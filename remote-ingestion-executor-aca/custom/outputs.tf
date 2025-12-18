# =============================================================================
# DataHub Remote Executor - Azure Container Apps (Minimal)
# Outputs
# =============================================================================

output "resource_group_name" {
  description = "The name of the resource group"
  value       = local.resource_group_name
}

output "container_app_environment_id" {
  description = "The ID of the Container App Environment"
  value       = azurerm_container_app_environment.this.id
}

output "container_app_id" {
  description = "The ID of the Container App"
  value       = azurerm_container_app.this.id
}

output "container_app_name" {
  description = "The name of the Container App"
  value       = azurerm_container_app.this.name
}
