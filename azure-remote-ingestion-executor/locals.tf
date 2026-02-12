locals {
  # Determine which executor ID variable to use (prefer executor_pool_id over deprecated executor_id)
  executor_pool_id = var.datahub.executor_pool_id != "remote" ? var.datahub.executor_pool_id : var.datahub.executor_id

  # Create conditional ranges for dynamic blocks
  image_registry_count = var.image_registry_credential != null ? 1 : 0
  identity_count       = var.identity_type != null ? 1 : 0
  diagnostics_count    = var.log_analytics_workspace_id != null ? 1 : 0

  # Convert volumes list to map for dynamic block iteration
  # Explicitly cast to map type to satisfy Terraform's for_each requirements
  volumes_map = length(var.volumes) > 0 ? { for idx in range(length(var.volumes)) : tostring(idx) => var.volumes[idx] } : {}
}
