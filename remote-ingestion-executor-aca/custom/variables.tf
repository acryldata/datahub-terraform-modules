# =============================================================================
# DataHub Remote Executor - Azure Container Apps (Minimal)
# Variables
# =============================================================================

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------

variable "create_resource_group" {
  description = "Whether to create a new resource group or use an existing one"
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the resource group (created or existing)"
  type        = string
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
}

# -----------------------------------------------------------------------------
# Naming
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "datahub-executor"
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "infrastructure_subnet_id" {
  description = "Subnet ID for Container App Environment. Must be /23 or larger and delegated to Microsoft.App/environments"
  type        = string
}

# -----------------------------------------------------------------------------
# Container Registry
# -----------------------------------------------------------------------------

variable "container_registry_url" {
  description = "Container registry server URL (e.g., myacr.azurecr.io)"
  type        = string
}

variable "container_registry_username" {
  description = "Container registry username"
  type        = string
}

variable "container_registry_password" {
  description = "Container registry password"
  type        = string
  sensitive   = true
}

variable "image_repository" {
  description = "Full container image repository path (e.g., myacr.azurecr.io/datahub-executor)"
  type        = string
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
  default     = "v0.3.15.3-acryl"
}

# -----------------------------------------------------------------------------
# DataHub Configuration
# -----------------------------------------------------------------------------

variable "datahub_gms_url" {
  description = "DataHub GMS endpoint URL (e.g., https://company.acryl.io/gms)"
  type        = string
}

variable "datahub_access_token" {
  description = "DataHub access token for authentication"
  type        = string
  sensitive   = true
}

variable "executor_pool_id" {
  description = "DataHub executor pool ID (must match the pool created in DataHub UI)"
  type        = string
}

# -----------------------------------------------------------------------------
# Resources (optional)
# -----------------------------------------------------------------------------

variable "cpu" {
  description = "CPU cores for the executor container"
  type        = number
  default     = 2.0
}

variable "memory" {
  description = "Memory for the executor container (e.g., '4Gi')"
  type        = string
  default     = "4Gi"
}
