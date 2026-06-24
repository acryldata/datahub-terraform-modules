# ============================================================================
# DataHub Remote Ingestion Executor - Azure Container Apps
# Main Terraform Configuration
# ============================================================================

# ============================================================================
# Log Analytics Workspace (for Container App Environment)
# ============================================================================

resource "azurerm_log_analytics_workspace" "executor" {
  count = var.create_container_app_environment && var.log_analytics_workspace_id == "" ? 1 : 0

  name                = "${var.name_prefix}-${var.environment}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge(var.tags, {
    app = "datahub-executor"
  })
}

# ============================================================================
# Container App Environment
# ============================================================================

resource "azurerm_container_app_environment" "executor" {
  count = var.create_container_app_environment ? 1 : 0

  name                           = "${var.name_prefix}-${var.environment}-env"
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : azurerm_log_analytics_workspace.executor[0].id
  infrastructure_subnet_id       = var.enable_vnet_integration ? var.infrastructure_subnet_id : null
  internal_load_balancer_enabled = var.enable_vnet_integration ? var.internal_load_balancer_enabled : null

  # Consumption workload profile (always required for workload profile environments)
  dynamic "workload_profile" {
    for_each = var.workload_profile_name != "" ? [1] : []
    content {
      name                  = "Consumption"
      workload_profile_type = "Consumption"
    }
  }

  # Dedicated workload profile for higher resources (4 CPU / 8Gi)
  dynamic "workload_profile" {
    for_each = var.workload_profile_name != "" ? [1] : []
    content {
      name                  = var.workload_profile_name
      workload_profile_type = "D4"
      minimum_count         = 1
      maximum_count         = 3
    }
  }

  tags = merge(var.tags, {
    app = "datahub-executor"
  })
}

# ============================================================================
# User Assigned Managed Identity
# ============================================================================

resource "azurerm_user_assigned_identity" "executor" {
  name                = "${var.name_prefix}-${var.environment}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    app = "datahub-executor"
  })
}

# ============================================================================
# Role Assignment: ACR Pull (if using Managed Identity for ACR)
# ============================================================================

resource "azurerm_role_assignment" "acr_pull" {
  count = var.enable_managed_identity_acr && var.acr_name != "" ? 1 : 0

  scope                = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${local.acr_resource_group}/providers/Microsoft.ContainerRegistry/registries/${var.acr_name}"
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.executor.principal_id
}

# ============================================================================
# Role Assignment: Key Vault Secrets User (if using Key Vault)
# ============================================================================

resource "azurerm_role_assignment" "key_vault_secrets" {
  count = var.key_vault_id != "" ? 1 : 0

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.executor.principal_id
}

# ============================================================================
# Container App
# ============================================================================

resource "azurerm_container_app" "executor" {
  name                         = "${var.name_prefix}-${var.environment}"
  container_app_environment_id = local.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"
  workload_profile_name        = var.workload_profile_name != "" ? var.workload_profile_name : null

  # Managed Identity
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.executor.id]
  }

  # Container Registry Configuration
  dynamic "registry" {
    for_each = var.enable_managed_identity_acr ? [1] : []
    content {
      server   = var.container_registry_url
      identity = azurerm_user_assigned_identity.executor.id
    }
  }

  dynamic "registry" {
    for_each = var.enable_managed_identity_acr ? [] : [1]
    content {
      server               = var.container_registry_url
      username             = var.container_registry_username
      password_secret_name = "registry-password"
    }
  }

  # Secrets
  # DataHub access token (either direct value or Key Vault reference)
  dynamic "secret" {
    for_each = var.datahub_access_token != "" ? [1] : []
    content {
      name  = "datahub-gms-token"
      value = var.datahub_access_token
    }
  }

  dynamic "secret" {
    for_each = var.datahub_access_token == "" && var.key_vault_id != "" ? [1] : []
    content {
      name                = "datahub-gms-token"
      key_vault_secret_id = "${var.key_vault_id}/secrets/${var.key_vault_secret_name}"
      identity            = azurerm_user_assigned_identity.executor.id
    }
  }

  # Registry password secret (if not using Managed Identity)
  dynamic "secret" {
    for_each = var.enable_managed_identity_acr ? [] : [1]
    content {
      name  = "registry-password"
      value = var.container_registry_password
    }
  }

  # Azure Files storage account key (if using Azure Files for CA certs)
  dynamic "secret" {
    for_each = var.azure_files_account_key != "" ? [1] : []
    content {
      name  = "storage-account-key"
      value = var.azure_files_account_key
    }
  }

  # Extra secret environment variables
  dynamic "secret" {
    for_each = nonsensitive(toset(keys(var.extra_secret_env_vars)))
    content {
      name  = "extra-secret-${lower(replace(secret.value, "_", "-"))}"
      value = var.extra_secret_env_vars[secret.value]
    }
  }

  # Template Configuration
  template {
    # Scaling configuration
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    # Workload profile for dedicated compute (optional)
    # When set, container can use up to 4 CPU / 8Gi
    # When not set (consumption plan), max is 2 CPU / 4Gi

    # Azure Files volume for CA certificates (optional)
    dynamic "volume" {
      for_each = var.azure_files_share_name != "" ? [1] : []
      content {
        name         = "ca-certs-volume"
        storage_type = "AzureFile"
        storage_name = var.azure_files_share_name
      }
    }

    # Main container
    container {
      name   = "datahub-executor"
      image  = "${var.image_repository}:${var.image_tag}"
      cpu    = var.cpu
      memory = var.memory

      # Startup command
      command = ["dockerize", "/start_datahub_executor.sh"]

      # ================================================================
      # Core Environment Variables
      # ================================================================

      env {
        name  = "DATAHUB_GMS_URL"
        value = var.datahub_gms_url
      }

      env {
        name        = "DATAHUB_GMS_TOKEN"
        secret_name = "datahub-gms-token"
      }

      env {
        name  = "DATAHUB_EXECUTOR_MODE"
        value = "worker"
      }

      env {
        name  = "DATAHUB_EXECUTOR_POOL_ID"
        value = var.executor_pool_id
      }

      # Legacy variable for backwards compatibility
      env {
        name  = "DATAHUB_EXECUTOR_WORKER_ID"
        value = var.executor_pool_id
      }

      # ================================================================
      # Worker Configuration
      # ================================================================

      env {
        name  = "DATAHUB_EXECUTOR_INGESTION_MAX_WORKERS"
        value = tostring(var.ingestion_max_workers)
      }

      env {
        name  = "DATAHUB_EXECUTOR_INGESTION_SIGNAL_POLL_INTERVAL"
        value = tostring(var.ingestion_signal_poll_interval)
      }

      env {
        name  = "DATAHUB_EXECUTOR_MONITORS_MAX_WORKERS"
        value = tostring(var.monitors_max_workers)
      }

      # ================================================================
      # Proxy Configuration (Locked-Down Environments)
      # ================================================================

      dynamic "env" {
        for_each = var.http_proxy != "" ? [1] : []
        content {
          name  = "HTTP_PROXY"
          value = var.http_proxy
        }
      }

      dynamic "env" {
        for_each = var.http_proxy != "" ? [1] : []
        content {
          name  = "http_proxy"
          value = var.http_proxy
        }
      }

      dynamic "env" {
        for_each = var.https_proxy != "" ? [1] : []
        content {
          name  = "HTTPS_PROXY"
          value = var.https_proxy
        }
      }

      dynamic "env" {
        for_each = var.https_proxy != "" ? [1] : []
        content {
          name  = "https_proxy"
          value = var.https_proxy
        }
      }

      dynamic "env" {
        for_each = var.no_proxy != "" ? [1] : []
        content {
          name  = "NO_PROXY"
          value = var.no_proxy
        }
      }

      dynamic "env" {
        for_each = var.no_proxy != "" ? [1] : []
        content {
          name  = "no_proxy"
          value = var.no_proxy
        }
      }

      # ================================================================
      # Custom CA Certificates
      # ================================================================

      dynamic "env" {
        for_each = var.custom_ca_cert_path != "" ? [1] : []
        content {
          name  = "SSL_CERT_FILE"
          value = var.custom_ca_cert_path
        }
      }

      dynamic "env" {
        for_each = var.custom_ca_cert_path != "" ? [1] : []
        content {
          name  = "REQUESTS_CA_BUNDLE"
          value = var.custom_ca_cert_path
        }
      }

      # ================================================================
      # Debug Mode
      # ================================================================

      dynamic "env" {
        for_each = var.enable_debug ? [1] : []
        content {
          name  = "DATAHUB_DEBUG"
          value = "true"
        }
      }

      # ================================================================
      # Extra Environment Variables (non-secret)
      # ================================================================

      dynamic "env" {
        for_each = var.extra_env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      # ================================================================
      # Extra Secret Environment Variables
      # ================================================================

      dynamic "env" {
        for_each = nonsensitive(toset(keys(var.extra_secret_env_vars)))
        content {
          name        = env.value
          secret_name = "extra-secret-${lower(replace(env.value, "_", "-"))}"
        }
      }

      # ================================================================
      # Volume Mounts (for CA certificates)
      # ================================================================

      dynamic "volume_mounts" {
        for_each = var.azure_files_share_name != "" ? [1] : []
        content {
          name = "ca-certs-volume"
          path = "/mnt/ca-certs"
        }
      }

      # ================================================================
      # Health Probes
      # ================================================================

      # Liveness probe - checks if the worker process is alive
      liveness_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/health"
        initial_delay           = var.liveness_probe_initial_delay
        interval_seconds        = var.liveness_probe_period
        failure_count_threshold = var.liveness_probe_failure_threshold
        timeout                 = var.liveness_probe_timeout
      }

      # Readiness probe - checks if the worker is ready to accept tasks
      readiness_probe {
        transport               = "HTTP"
        port                    = 8080
        path                    = "/health"
        initial_delay           = var.readiness_probe_initial_delay
        interval_seconds        = var.readiness_probe_period
        failure_count_threshold = var.readiness_probe_failure_threshold
        timeout                 = var.readiness_probe_timeout
      }
    }

    # Revision suffix (for blue-green deployments)
    revision_suffix = var.revision_suffix != "" ? var.revision_suffix : null
  }

  # No ingress required - executor is outbound-only
  # ingress block is omitted intentionally

  tags = merge(var.tags, {
    app = "datahub-executor"
  })

  # Ensure identity and role assignments are created first
  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.key_vault_secrets
  ]
}

# ============================================================================
# Azure Files Storage (Optional - for CA certificates)
# ============================================================================

resource "azurerm_container_app_environment_storage" "ca_certs" {
  count = var.azure_files_share_name != "" && var.create_container_app_environment ? 1 : 0

  name                         = "ca-certs-storage"
  container_app_environment_id = azurerm_container_app_environment.executor[0].id
  account_name                 = var.azure_files_account_name
  share_name                   = var.azure_files_share_name
  access_key                   = var.azure_files_account_key
  access_mode                  = "ReadOnly"
}

# ============================================================================
# Data Sources
# ============================================================================

data "azurerm_subscription" "current" {}
