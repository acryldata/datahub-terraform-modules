# Data sources for the Azure Remote Ingestion Executor module
#
# This file contains examples of common data sources you might want to use
# when deploying the executor. Uncomment and modify as needed for your use case.

# Example: Reference an existing resource group
# Useful if you want to deploy to an existing resource group instead of creating a new one
# data "azurerm_resource_group" "executor" {
#   name = "rg-datahub-executor"
# }

# Example: Reference an existing subnet for private networking
# Useful when deploying with ip_address_type = "Private"
# data "azurerm_subnet" "executor" {
#   name                 = "subnet-executor"
#   virtual_network_name = "vnet-datahub"
#   resource_group_name  = "rg-datahub-network"
# }

# Example: Reference an existing Log Analytics workspace
# Useful for enabling container logging and monitoring
# data "azurerm_log_analytics_workspace" "main" {
#   name                = "law-datahub"
#   resource_group_name = "rg-datahub-monitoring"
# }

# Example: Reference an existing Azure Container Registry
# Useful for pulling private container images
# data "azurerm_container_registry" "main" {
#   name                = "acrydatahub"
#   resource_group_name = "rg-datahub-shared"
# }

# Example: Reference an existing User Assigned Identity
# Useful when using identity_type = "UserAssigned"
# data "azurerm_user_assigned_identity" "executor" {
#   name                = "id-datahub-executor"
#   resource_group_name = "rg-datahub-identity"
# }

# Example: Reference an existing Key Vault
# Useful for retrieving secrets via managed identity
# data "azurerm_key_vault" "main" {
#   name                = "kv-datahub"
#   resource_group_name = "rg-datahub-security"
# }

# Example: Reference an existing Key Vault secret
# Useful for passing secret values to the container
# data "azurerm_key_vault_secret" "datahub_token" {
#   name         = "datahub-gms-token"
#   key_vault_id = data.azurerm_key_vault.main.id
# }

# Example: Reference an existing Storage Account
# Useful for mounting Azure Files volumes
# data "azurerm_storage_account" "executor" {
#   name                = "stdatahubexecutor"
#   resource_group_name = "rg-datahub-storage"
# }

# Example: Get current client configuration
# Useful for dynamic configurations based on the executing identity
# data "azurerm_client_config" "current" {}

# Example: Get current subscription
# Useful for building resource IDs or conditional logic
# data "azurerm_subscription" "current" {}
