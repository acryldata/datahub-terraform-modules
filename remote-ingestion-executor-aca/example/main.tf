# ============================================================================
# DataHub Remote Ingestion Executor - Azure Container Apps
# Example Deployment
# ============================================================================
#
# This example demonstrates deploying the DataHub Remote Executor on Azure
# Container Apps with various configuration options.
#
# Usage:
#   1. Copy terraform.tfvars.example to terraform.tfvars
#   2. Fill in your values
#   3. Run: terraform init && terraform apply
#
# ============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

# ============================================================================
# Provider Configuration
# ============================================================================

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# ============================================================================
# Variables
# ============================================================================

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "datahub_gms_url" {
  description = "DataHub GMS URL"
  type        = string
}

variable "datahub_access_token" {
  description = "DataHub access token"
  type        = string
  sensitive   = true
}

variable "executor_pool_id" {
  description = "Executor pool ID"
  type        = string
  default     = "aca-executor-pool"
}

variable "acr_name" {
  description = "Azure Container Registry name"
  type        = string
}

variable "image_tag" {
  description = "DataHub executor image tag"
  type        = string
  default     = "v0.3.15.3-acryl"
}

# ============================================================================
# Resource Group (if needed)
# ============================================================================

# Uncomment to create a new resource group
# resource "azurerm_resource_group" "main" {
#   name     = var.resource_group_name
#   location = var.location
# }

# ============================================================================
# DataHub Executor Module - Basic Deployment
# ============================================================================

module "datahub_executor" {
  source = "../"

  # Azure Configuration
  resource_group_name = var.resource_group_name
  location            = var.location
  environment         = var.environment
  name_prefix         = "datahub-executor"

  # DataHub Configuration
  datahub_gms_url      = var.datahub_gms_url
  datahub_access_token = var.datahub_access_token
  executor_pool_id     = var.executor_pool_id

  # Container Image (using ACR)
  image_repository            = "${var.acr_name}.azurecr.io/datahub-executor"
  image_tag                   = var.image_tag
  container_registry_url      = "${var.acr_name}.azurecr.io"
  enable_managed_identity_acr = true
  acr_name                    = var.acr_name

  # Resource Configuration
  cpu    = 2.0
  memory = "4Gi"

  # Scaling
  min_replicas = 1
  max_replicas = 3

  # Worker Configuration
  ingestion_max_workers          = 4
  monitors_max_workers           = 10
  ingestion_signal_poll_interval = 2

  # Tags
  tags = {
    Project     = "DataHub"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# Outputs
# ============================================================================

output "container_app_name" {
  description = "Name of the Container App"
  value       = module.datahub_executor.container_app_name
}

output "container_app_id" {
  description = "ID of the Container App"
  value       = module.datahub_executor.container_app_id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = module.datahub_executor.managed_identity_principal_id
}

output "deployment_summary" {
  description = "Deployment configuration summary"
  value       = module.datahub_executor.deployment_summary
}

# ============================================================================
# Example: Locked-Down Environment with VNet Integration
# ============================================================================
#
# Uncomment and modify the following for locked-down environments:
#
# # VNet for Container Apps
# resource "azurerm_virtual_network" "main" {
#   name                = "datahub-vnet"
#   location            = var.location
#   resource_group_name = var.resource_group_name
#   address_space       = ["10.0.0.0/16"]
# }
#
# # Subnet for Container App Environment (must be /23 or larger)
# resource "azurerm_subnet" "aca" {
#   name                 = "aca-subnet"
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = azurerm_virtual_network.main.name
#   address_prefixes     = ["10.0.0.0/23"]
#
#   delegation {
#     name = "aca-delegation"
#     service_delegation {
#       name = "Microsoft.App/environments"
#       actions = [
#         "Microsoft.Network/virtualNetworks/subnets/join/action",
#       ]
#     }
#   }
# }
#
# module "datahub_executor_locked_down" {
#   source = "../"
#
#   # ... base configuration ...
#
#   # VNet Integration
#   enable_vnet_integration        = true
#   infrastructure_subnet_id       = azurerm_subnet.aca.id
#   internal_load_balancer_enabled = true
#
#   # Proxy Configuration
#   http_proxy  = "http://proxy.company.com:8080"
#   https_proxy = "http://proxy.company.com:8080"
#   no_proxy    = "localhost,127.0.0.1,.internal.company.com"
# }

# ============================================================================
# Example: Using Key Vault for Secrets
# ============================================================================
#
# Uncomment for Key Vault integration:
#
# data "azurerm_client_config" "current" {}
#
# resource "azurerm_key_vault" "main" {
#   name                       = "datahub-kv-${var.environment}"
#   location                   = var.location
#   resource_group_name        = var.resource_group_name
#   tenant_id                  = data.azurerm_client_config.current.tenant_id
#   sku_name                   = "standard"
#   soft_delete_retention_days = 7
#   purge_protection_enabled   = false
#
#   access_policy {
#     tenant_id = data.azurerm_client_config.current.tenant_id
#     object_id = data.azurerm_client_config.current.object_id
#
#     secret_permissions = [
#       "Get", "List", "Set", "Delete", "Purge"
#     ]
#   }
# }
#
# resource "azurerm_key_vault_secret" "datahub_token" {
#   name         = "datahub-access-token"
#   value        = var.datahub_access_token
#   key_vault_id = azurerm_key_vault.main.id
# }
#
# module "datahub_executor_with_keyvault" {
#   source = "../"
#
#   # ... base configuration ...
#
#   # Use Key Vault instead of direct token
#   datahub_access_token  = ""  # Leave empty when using Key Vault
#   key_vault_id          = azurerm_key_vault.main.id
#   key_vault_secret_name = "datahub-access-token"
# }
