# =============================================================================
# DataHub Remote Executor - Azure Container Apps (Minimal)
# Main Configuration
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Group (conditional)
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "this" {
  count    = var.create_resource_group ? 1 : 0
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.this[0].name : var.resource_group_name
}

# -----------------------------------------------------------------------------
# Container App Environment (VNet-integrated)
# -----------------------------------------------------------------------------

resource "azurerm_container_app_environment" "this" {
  name                     = "${var.name_prefix}-${var.environment}-env"
  location                 = var.location
  resource_group_name      = local.resource_group_name
  infrastructure_subnet_id = var.infrastructure_subnet_id
  tags                     = var.tags
}

# -----------------------------------------------------------------------------
# Container App
# -----------------------------------------------------------------------------

resource "azurerm_container_app" "this" {
  name                         = "${var.name_prefix}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = local.resource_group_name
  revision_mode                = "Single"

  # Container Registry
  registry {
    server               = var.container_registry_url
    username             = var.container_registry_username
    password_secret_name = "registry-password"
  }

  # Secrets
  secret {
    name  = "registry-password"
    value = var.container_registry_password
  }

  secret {
    name  = "datahub-gms-token"
    value = var.datahub_access_token
  }

  # Template
  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "datahub-executor"
      image  = "${var.image_repository}:${var.image_tag}"
      cpu    = var.cpu
      memory = var.memory

      # Startup command - run executor directly without dockerize wait
      command = ["/start_datahub_executor.sh"]

      # Core DataHub environment variables
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

      env {
        name  = "DATAHUB_EXECUTOR_WORKER_ID"
        value = var.executor_pool_id
      }
    }
  }

  tags = var.tags
}
