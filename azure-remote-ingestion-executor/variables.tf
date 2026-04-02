variable "datahub" {
  description = "Acryl Executor configuration"
  type = object({
    # The container image (defaults to Cloudsmith registry for cross-cloud compatibility)
    image     = optional(string, "docker.datahub.com/re/datahub-executor")
    image_tag = optional(string, "v0.3.16.2-acryl")
    # Acryl DataHub URL: The URL for your DataHub instance, e.g. <your-company>.acryl.io/gms
    url = string

    # Unique Executor Pool Id. Warning - do not change this without consulting with your Acryl rep
    executor_pool_id = optional(string, "remote")

    # This variable is DEPRECATED. Use executor_pool_id instead.
    executor_id = optional(string, "remote")

    # Number of worker threads for ingestion jobs
    executor_ingestions_workers = optional(number, 4)
    # Number of worker threads for monitor jobs
    executor_monitors_workers = optional(number, 10)
    # Ingestion signal poll interval in seconds
    executor_ingestions_poll_interval = optional(number, 5)
  })
}

variable "name" {
  description = "Name of the container group and container"
  type        = string
  default     = "dh-remote-executor"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "cpu" {
  description = "Number of CPU cores for the container"
  type        = number
  default     = 4
}

variable "memory" {
  description = "Amount of memory in GB for the container"
  type        = number
  default     = 8
}

variable "restart_policy" {
  description = "Restart policy for the container group (Always, OnFailure, Never)"
  type        = string
  default     = "Always"

  validation {
    condition     = contains(["Always", "OnFailure", "Never"], var.restart_policy)
    error_message = "restart_policy must be one of: Always, OnFailure, Never"
  }
}

variable "os_type" {
  description = "The OS type for the container (Linux or Windows)"
  type        = string
  default     = "Linux"
}

variable "ip_address_type" {
  description = "The IP address type for the container group (Public or Private)"
  type        = string
  default     = "Public"
  validation {
    condition     = contains(["Public", "Private", "None"], var.ip_address_type)
    error_message = "ip_address_type must be one of: Public, Private, None"
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate with the container group (required for Private IP address type)"
  type        = list(string)
  default     = []
}

variable "dns_name_label" {
  description = "The DNS name label for the container group (optional, for public IP only)"
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Environment variables to pass to the container (non-sensitive)"
  type        = map(string)
  default     = {}
}

variable "secure_environment_variables" {
  description = "Secure environment variables to pass to the container (sensitive values)"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "image_registry_credential" {
  description = "Container image registry credentials"
  type = object({
    server   = string
    username = string
    password = string
  })
  default   = null
  sensitive = true
}

variable "identity_type" {
  description = "The type of managed identity (SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned)"
  type        = string
  default     = null

  validation {
    condition     = var.identity_type == null ? true : contains(["SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"], var.identity_type)
    error_message = "identity_type must be one of: SystemAssigned, UserAssigned, or 'SystemAssigned, UserAssigned'"
  }
}

variable "identity_ids" {
  description = "List of user assigned identity IDs to associate with the container group"
  type        = list(string)
  default     = []
}

variable "key_vault_key_id" {
  description = "The Key Vault key ID to use for encryption"
  type        = string
  default     = null
}

variable "key_vault_user_assigned_identity_id" {
  description = "The user assigned identity ID to use for Key Vault encryption"
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "The Log Analytics workspace ID for container logs"
  type        = string
  default     = null
}

variable "log_analytics_workspace_key" {
  description = "The Log Analytics workspace key for container logs"
  type        = string
  default     = null
  sensitive   = true
}

variable "log_type" {
  description = "The log type for diagnostics (ContainerInsights or ContainerInstanceLogs)"
  type        = string
  default     = "ContainerInsights"

  validation {
    condition     = contains(["ContainerInsights", "ContainerInstanceLogs"], var.log_type)
    error_message = "log_type must be one of: ContainerInsights, ContainerInstanceLogs"
  }
}

variable "exposed_ports" {
  description = "List of ports to expose on the container"
  type = list(object({
    port     = number
    protocol = string
  }))
  default = []
}

variable "volumes" {
  description = "List of volumes to mount to the container"
  type = list(object({
    name                 = string
    mount_path           = string
    read_only            = optional(bool, false)
    empty_dir            = optional(bool, false)
    storage_account_name = optional(string)
    storage_account_key  = optional(string)
    share_name           = optional(string)
    git_repo_url         = optional(string)
    git_repo_directory   = optional(string)
    git_repo_revision    = optional(string)
    secret               = optional(map(string))
  }))
  default   = []
  sensitive = true
}

variable "readiness_probe" {
  description = "Readiness probe configuration"
  type = object({
    exec                  = optional(list(string))
    http_get_path         = optional(string)
    http_get_port         = optional(number)
    http_get_scheme       = optional(string)
    initial_delay_seconds = optional(number, 60)
    period_seconds        = optional(number, 60)
    failure_threshold     = optional(number, 3)
    success_threshold     = optional(number, 1)
    timeout_seconds       = optional(number, 5)
  })
  default = {
    exec                  = ["/health_status", "/tmp/worker_readiness_heartbeat"]
    initial_delay_seconds = 60
    period_seconds        = 60
    failure_threshold     = 3
    success_threshold     = 1
    timeout_seconds       = 5
  }
}

variable "liveness_probe" {
  description = "Liveness probe configuration"
  type = object({
    exec                  = optional(list(string))
    http_get_path         = optional(string)
    http_get_port         = optional(number)
    http_get_scheme       = optional(string)
    initial_delay_seconds = optional(number, 60)
    period_seconds        = optional(number, 60)
    failure_threshold     = optional(number, 3)
    timeout_seconds       = optional(number, 5)
  })
  default = {
    exec                  = ["/health_status", "/tmp/worker_liveness_heartbeat"]
    initial_delay_seconds = 60
    period_seconds        = 60
    failure_threshold     = 3
    timeout_seconds       = 5
  }
}

variable "commands" {
  description = "Commands to run in the container"
  type        = list(string)
  default     = ["dockerize", "/start_datahub_executor.sh"]
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "zones" {
  description = "List of availability zones for the container group"
  type        = list(string)
  default     = null
}
