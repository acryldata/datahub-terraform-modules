# ============================================================================
# DataHub Remote Ingestion Executor - Azure Container Apps
# Terraform Variables
# ============================================================================

# ============================================================================
# Azure Configuration
# ============================================================================

variable "resource_group_name" {
  description = "The name of the resource group where resources will be created"
  type        = string
}

variable "location" {
  description = "Azure region for all resources (e.g., eastus, westeurope)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod) - used for resource naming and tagging"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "name_prefix" {
  description = "Prefix for resource names (e.g., 'mycompany-datahub')"
  type        = string
  default     = "datahub-executor"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Container App Environment Configuration
# ============================================================================

variable "create_container_app_environment" {
  description = "Whether to create a new Container App Environment or use an existing one"
  type        = bool
  default     = true
}

variable "container_app_environment_id" {
  description = "ID of an existing Container App Environment (required if create_container_app_environment is false)"
  type        = string
  default     = ""
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for Container App Environment logs (optional, creates new if not provided)"
  type        = string
  default     = ""
}

# ============================================================================
# VNet Integration (for Locked-Down Environments)
# ============================================================================

variable "enable_vnet_integration" {
  description = "Enable VNet integration for the Container App Environment (required for locked-down environments)"
  type        = bool
  default     = false
}

variable "infrastructure_subnet_id" {
  description = "Subnet ID for Container App Environment infrastructure (required if enable_vnet_integration is true). Subnet must be delegated to Microsoft.App/environments and be at least /23"
  type        = string
  default     = ""
}

variable "internal_load_balancer_enabled" {
  description = "Should the Container Environment operate in Internal Load Balancing Mode (no public IP)"
  type        = bool
  default     = false
}

# ============================================================================
# DataHub Configuration
# ============================================================================

variable "datahub_gms_url" {
  description = "DataHub GMS endpoint URL (e.g., https://your-company.acryl.io/gms)"
  type        = string
}

variable "datahub_access_token" {
  description = "DataHub access token for authentication. Either provide this or use Key Vault reference via key_vault_secret_id"
  type        = string
  sensitive   = true
  default     = ""
}

variable "key_vault_id" {
  description = "Azure Key Vault ID for storing/retrieving secrets (optional, for Key Vault integration)"
  type        = string
  default     = ""
}

variable "key_vault_secret_name" {
  description = "Name of the secret in Key Vault containing the DataHub access token (required if using Key Vault)"
  type        = string
  default     = "datahub-access-token"
}

variable "executor_pool_id" {
  description = "DataHub executor pool ID (must match the pool created in DataHub UI)"
  type        = string
  default     = "aca-executor-pool"
}

# ============================================================================
# Container Image Configuration
# ============================================================================

variable "image_repository" {
  description = "DataHub executor container image repository (e.g., myacr.azurecr.io/datahub-executor)"
  type        = string
}

variable "image_tag" {
  description = "DataHub executor container image tag"
  type        = string
  default     = "v0.3.15.3-acryl"
}

# ============================================================================
# Container Registry Configuration
# ============================================================================

variable "container_registry_url" {
  description = "Container registry server URL (e.g., myacr.azurecr.io)"
  type        = string
}

variable "enable_managed_identity_acr" {
  description = "Use Managed Identity for ACR authentication (recommended). If false, provide username/password"
  type        = bool
  default     = true
}

variable "acr_name" {
  description = "Azure Container Registry name (required if enable_managed_identity_acr is true)"
  type        = string
  default     = ""
}

variable "acr_resource_group_name" {
  description = "Resource group name where ACR is located (defaults to resource_group_name if not specified)"
  type        = string
  default     = ""
}

variable "container_registry_username" {
  description = "Container registry username (required if enable_managed_identity_acr is false)"
  type        = string
  default     = ""
}

variable "container_registry_password" {
  description = "Container registry password (required if enable_managed_identity_acr is false)"
  type        = string
  sensitive   = true
  default     = ""
}

# ============================================================================
# Container Resource Configuration
# ============================================================================

variable "cpu" {
  description = "CPU cores for the executor container (0.25 - 4.0). Note: ACA max is 4 cores"
  type        = number
  default     = 4.0

  validation {
    condition     = var.cpu >= 0.25 && var.cpu <= 4.0
    error_message = "CPU must be between 0.25 and 4.0 cores (ACA limit)."
  }
}

variable "memory" {
  description = "Memory for the executor container (e.g., '8Gi'). Note: ACA max is 8Gi"
  type        = string
  default     = "8Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.memory))
    error_message = "Memory must be in format like '4Gi' or '0.5Gi'."
  }
}

# ============================================================================
# Scaling Configuration
# ============================================================================

variable "min_replicas" {
  description = "Minimum number of container replicas (must be >= 1 for always-on executor)"
  type        = number
  default     = 1

  validation {
    condition     = var.min_replicas >= 1
    error_message = "min_replicas must be at least 1 for the executor to function (it's a polling-based worker)."
  }
}

variable "max_replicas" {
  description = "Maximum number of container replicas for autoscaling"
  type        = number
  default     = 3

  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 30
    error_message = "max_replicas must be between 1 and 30."
  }
}

# ============================================================================
# Executor Worker Configuration
# ============================================================================

variable "ingestion_max_workers" {
  description = "Maximum number of concurrent ingestion workers per replica"
  type        = number
  default     = 4
}

variable "ingestion_signal_poll_interval" {
  description = "Signal polling interval for ingestion workers (seconds)"
  type        = number
  default     = 2
}

variable "monitors_max_workers" {
  description = "Maximum number of concurrent monitor/assertion workers per replica"
  type        = number
  default     = 10
}

# ============================================================================
# Health Check Configuration
# ============================================================================

variable "liveness_probe_initial_delay" {
  description = "Initial delay before liveness probe starts (seconds)"
  type        = number
  default     = 60
}

variable "liveness_probe_period" {
  description = "Period between liveness probes (seconds)"
  type        = number
  default     = 60
}

variable "liveness_probe_failure_threshold" {
  description = "Number of consecutive failures before container is restarted"
  type        = number
  default     = 3
}

variable "liveness_probe_timeout" {
  description = "Timeout for liveness probe (seconds)"
  type        = number
  default     = 5
}

variable "readiness_probe_initial_delay" {
  description = "Initial delay before readiness probe starts (seconds)"
  type        = number
  default     = 60
}

variable "readiness_probe_period" {
  description = "Period between readiness probes (seconds)"
  type        = number
  default     = 60
}

variable "readiness_probe_failure_threshold" {
  description = "Number of consecutive failures before container is marked unready"
  type        = number
  default     = 3
}

variable "readiness_probe_timeout" {
  description = "Timeout for readiness probe (seconds)"
  type        = number
  default     = 5
}

# ============================================================================
# Network Configuration (Locked-Down Environments)
# ============================================================================

variable "http_proxy" {
  description = "HTTP proxy URL for outbound connections (e.g., http://proxy.company.com:8080)"
  type        = string
  default     = ""
}

variable "https_proxy" {
  description = "HTTPS proxy URL for outbound connections (e.g., http://proxy.company.com:8080)"
  type        = string
  default     = ""
}

variable "no_proxy" {
  description = "Comma-separated list of hosts that should bypass the proxy"
  type        = string
  default     = "localhost,127.0.0.1"
}

# ============================================================================
# Custom CA Certificates (Locked-Down Environments)
# ============================================================================

variable "custom_ca_cert_path" {
  description = "Path inside container where custom CA certificates are mounted (if using Azure Files volume)"
  type        = string
  default     = ""
}

variable "azure_files_share_name" {
  description = "Azure Files share name for mounting custom CA certificates or other files"
  type        = string
  default     = ""
}

variable "azure_files_account_name" {
  description = "Azure Storage account name for Azure Files"
  type        = string
  default     = ""
}

variable "azure_files_account_key" {
  description = "Azure Storage account key for Azure Files"
  type        = string
  sensitive   = true
  default     = ""
}

# ============================================================================
# Additional Environment Variables
# ============================================================================

variable "extra_env_vars" {
  description = "Additional environment variables to set on the container (map of name to value)"
  type        = map(string)
  default     = {}
}

variable "extra_secret_env_vars" {
  description = "Additional secret environment variables (map of env var name to secret value). These will be stored as ACA secrets"
  type        = map(string)
  sensitive   = true
  default     = {}
}

# ============================================================================
# Debug and Advanced Configuration
# ============================================================================

variable "enable_debug" {
  description = "Enable debug mode for DataHub executor (sets DATAHUB_DEBUG=true)"
  type        = bool
  default     = false
}

variable "revision_suffix" {
  description = "Suffix for the container app revision (optional, for blue-green deployments)"
  type        = string
  default     = ""
}

variable "workload_profile_name" {
  description = "Name of the workload profile to use (for dedicated compute). Leave empty for consumption plan"
  type        = string
  default     = ""
}
