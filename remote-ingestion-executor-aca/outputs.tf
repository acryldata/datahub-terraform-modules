# ============================================================================
# DataHub Remote Ingestion Executor - Azure Container Apps
# Outputs
# ============================================================================

# ============================================================================
# Container App Outputs
# ============================================================================

output "container_app_id" {
  description = "The ID of the Container App"
  value       = azurerm_container_app.executor.id
}

output "container_app_name" {
  description = "The name of the Container App"
  value       = azurerm_container_app.executor.name
}

output "container_app_fqdn" {
  description = "The FQDN of the Container App (if ingress is enabled)"
  value       = try(azurerm_container_app.executor.ingress[0].fqdn, null)
}

output "latest_revision_name" {
  description = "The name of the latest revision"
  value       = azurerm_container_app.executor.latest_revision_name
}

output "latest_revision_fqdn" {
  description = "The FQDN of the latest revision"
  value       = azurerm_container_app.executor.latest_revision_fqdn
}

# ============================================================================
# Container App Environment Outputs
# ============================================================================

output "container_app_environment_id" {
  description = "The ID of the Container App Environment"
  value       = local.container_app_environment_id
}

output "container_app_environment_name" {
  description = "The name of the Container App Environment (if created by this module)"
  value       = var.create_container_app_environment ? azurerm_container_app_environment.executor[0].name : null
}

output "container_app_environment_default_domain" {
  description = "The default domain of the Container App Environment"
  value       = var.create_container_app_environment ? azurerm_container_app_environment.executor[0].default_domain : null
}

output "container_app_environment_static_ip" {
  description = "The static IP of the Container App Environment (when VNet integrated)"
  value       = var.create_container_app_environment ? azurerm_container_app_environment.executor[0].static_ip_address : null
}

# ============================================================================
# Managed Identity Outputs
# ============================================================================

output "managed_identity_id" {
  description = "The ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.executor.id
}

output "managed_identity_principal_id" {
  description = "The Principal ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.executor.principal_id
}

output "managed_identity_client_id" {
  description = "The Client ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.executor.client_id
}

output "managed_identity_tenant_id" {
  description = "The Tenant ID of the User Assigned Managed Identity"
  value       = azurerm_user_assigned_identity.executor.tenant_id
}

# ============================================================================
# Log Analytics Outputs
# ============================================================================

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace (if created by this module)"
  value       = var.create_container_app_environment && var.log_analytics_workspace_id == "" ? azurerm_log_analytics_workspace.executor[0].id : var.log_analytics_workspace_id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace (if created by this module)"
  value       = var.create_container_app_environment && var.log_analytics_workspace_id == "" ? azurerm_log_analytics_workspace.executor[0].name : null
}

# ============================================================================
# Configuration Outputs
# ============================================================================

output "executor_pool_id" {
  description = "The DataHub executor pool ID configured for this deployment"
  value       = var.executor_pool_id
}

output "datahub_gms_url" {
  description = "The DataHub GMS URL configured for this deployment"
  value       = var.datahub_gms_url
}

output "container_image" {
  description = "The full container image reference"
  value       = "${var.image_repository}:${var.image_tag}"
}

# ============================================================================
# Network Configuration Outputs
# ============================================================================

output "vnet_integration_enabled" {
  description = "Whether VNet integration is enabled"
  value       = var.enable_vnet_integration
}

output "internal_load_balancer_enabled" {
  description = "Whether internal load balancer is enabled (no public IP)"
  value       = var.internal_load_balancer_enabled
}

output "proxy_configured" {
  description = "Whether proxy settings are configured"
  value       = local.proxy_enabled
}

# ============================================================================
# Scaling Configuration Outputs
# ============================================================================

output "min_replicas" {
  description = "Minimum number of replicas configured"
  value       = var.min_replicas
}

output "max_replicas" {
  description = "Maximum number of replicas configured"
  value       = var.max_replicas
}

# ============================================================================
# Resource Summary (for debugging/documentation)
# ============================================================================

output "deployment_summary" {
  description = "Summary of the deployment configuration"
  sensitive   = true
  value = {
    container_app_name     = azurerm_container_app.executor.name
    environment            = var.environment
    executor_pool_id       = var.executor_pool_id
    datahub_gms_url        = var.datahub_gms_url
    image                  = "${var.image_repository}:${var.image_tag}"
    cpu                    = var.cpu
    memory                 = var.memory
    min_replicas           = var.min_replicas
    max_replicas           = var.max_replicas
    ingestion_max_workers  = var.ingestion_max_workers
    monitors_max_workers   = var.monitors_max_workers
    vnet_integrated        = var.enable_vnet_integration
    internal_only          = var.internal_load_balancer_enabled
    proxy_configured       = local.proxy_enabled
    using_key_vault        = local.use_key_vault_for_token
    using_managed_identity = var.enable_managed_identity_acr
  }
}
