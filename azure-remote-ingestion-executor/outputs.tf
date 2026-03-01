output "container_group_id" {
  description = "The ID of the container group"
  value       = azurerm_container_group.executor.id
}

output "container_group_name" {
  description = "The name of the container group"
  value       = azurerm_container_group.executor.name
}

output "ip_address" {
  description = "The IP address allocated to the container group"
  value       = azurerm_container_group.executor.ip_address
}

output "fqdn" {
  description = "The FQDN of the container group"
  value       = azurerm_container_group.executor.fqdn
}

output "identity" {
  description = "The managed identity information"
  value = var.identity_type != null ? {
    type         = azurerm_container_group.executor.identity[0].type
    principal_id = try(azurerm_container_group.executor.identity[0].principal_id, null)
    tenant_id    = try(azurerm_container_group.executor.identity[0].tenant_id, null)
    identity_ids = try(azurerm_container_group.executor.identity[0].identity_ids, null)
  } : null
}
