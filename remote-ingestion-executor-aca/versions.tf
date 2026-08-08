# ============================================================================
# DataHub Remote Ingestion Executor - Azure Container Apps
# Terraform and Provider Requirements
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

# Note: The azurerm provider must be configured in the root module.
# Example configuration:
#
# provider "azurerm" {
#   features {}
#   subscription_id = var.subscription_id
# }
