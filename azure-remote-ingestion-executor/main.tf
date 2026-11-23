resource "azurerm_container_group" "executor" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.os_type
  restart_policy      = var.restart_policy
  ip_address_type     = var.ip_address_type
  dns_name_label      = var.ip_address_type == "Public" ? var.dns_name_label : null
  subnet_ids          = var.ip_address_type == "Private" ? var.subnet_ids : null
  zones               = var.zones

  container {
    name   = var.name
    image  = format("%s:%s", var.datahub.image, var.datahub.image_tag)
    cpu    = var.cpu
    memory = var.memory

    commands = var.commands

    # Environment variables for DataHub Executor configuration
    environment_variables = merge(
      var.environment_variables,
      {
        DATAHUB_GMS_URL                                 = var.datahub.url
        DATAHUB_EXECUTOR_POOL_ID                        = local.executor_pool_id
        DATAHUB_EXECUTOR_WORKER_ID                      = local.executor_pool_id
        DATAHUB_EXECUTOR_MODE                           = "worker"
        DATAHUB_EXECUTOR_INGESTION_MAX_WORKERS          = tostring(var.datahub.executor_ingestions_workers)
        DATAHUB_EXECUTOR_MONITORS_MAX_WORKERS           = tostring(var.datahub.executor_monitors_workers)
        DATAHUB_EXECUTOR_INGESTION_SIGNAL_POLL_INTERVAL = tostring(var.datahub.executor_ingestions_poll_interval)
      }
    )

    secure_environment_variables = var.secure_environment_variables

    # Configure exposed ports if any
    dynamic "ports" {
      for_each = var.exposed_ports
      content {
        port     = ports.value.port
        protocol = ports.value.protocol
      }
    }

    # Configure readiness probe
    dynamic "readiness_probe" {
      for_each = var.readiness_probe != null && var.readiness_probe.exec != null ? [1] : []
      content {
        exec                  = var.readiness_probe.exec
        initial_delay_seconds = var.readiness_probe.initial_delay_seconds
        period_seconds        = var.readiness_probe.period_seconds
        failure_threshold     = var.readiness_probe.failure_threshold
        success_threshold     = var.readiness_probe.success_threshold
        timeout_seconds       = var.readiness_probe.timeout_seconds
      }
    }

    # Configure liveness probe
    dynamic "liveness_probe" {
      for_each = var.liveness_probe != null && var.liveness_probe.exec != null ? [1] : []
      content {
        exec                  = var.liveness_probe.exec
        initial_delay_seconds = var.liveness_probe.initial_delay_seconds
        period_seconds        = var.liveness_probe.period_seconds
        failure_threshold     = var.liveness_probe.failure_threshold
        timeout_seconds       = var.liveness_probe.timeout_seconds
      }
    }

    # Configure volume mounts
    dynamic "volume" {
      for_each = local.volumes_map
      content {
        name       = volume.value.name
        mount_path = volume.value.mount_path
        read_only  = volume.value.read_only

        # Empty directory volume
        empty_dir = volume.value.empty_dir

        # Azure Files volume
        storage_account_name = volume.value.storage_account_name
        storage_account_key  = volume.value.storage_account_key
        share_name           = volume.value.share_name

        # Git repo volume (only include if git_repo_url is set)
        dynamic "git_repo" {
          for_each = volume.value.git_repo_url != null ? [1] : []
          content {
            url       = volume.value.git_repo_url
            directory = volume.value.git_repo_directory
            revision  = volume.value.git_repo_revision
          }
        }

        # Secret volume
        secret = volume.value.secret
      }
    }
  }

  # Image registry credentials
  dynamic "image_registry_credential" {
    for_each = range(local.image_registry_count)
    content {
      server   = var.image_registry_credential.server
      username = var.image_registry_credential.username
      password = var.image_registry_credential.password
    }
  }

  # Managed identity configuration
  dynamic "identity" {
    for_each = range(local.identity_count)
    content {
      type         = var.identity_type
      identity_ids = var.identity_type != "SystemAssigned" ? var.identity_ids : null
    }
  }

  # Log Analytics diagnostics
  dynamic "diagnostics" {
    for_each = range(local.diagnostics_count)
    content {
      log_analytics {
        workspace_id  = var.log_analytics_workspace_id
        workspace_key = var.log_analytics_workspace_key
        log_type      = var.log_type
      }
    }
  }

  tags = var.tags
}
