# Terraform variables for DataHub Remote Executor deployment on AKS

# Azure Configuration
variable "subscription_id" {
  description = "The Azure subscription ID where resources will be created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group containing the AKS cluster"
  type        = string
}

variable "aks_cluster_name" {
  description = "The name of the existing AKS cluster"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for DataHub executor deployment"
  type        = string
  default     = "datahub-remote-executor"
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

# DataHub Configuration
variable "datahub_gms_url" {
  description = "DataHub GMS endpoint URL (e.g., https://your-company.acryl.io/gms)"
  type        = string
}

variable "datahub_access_token" {
  description = "DataHub access token for authentication (generated from DataHub UI)"
  type        = string
  sensitive   = true
}

variable "datahub_remote_executor_pool_id" {
  description = "DataHub executor pool ID (must match the pool created in DataHub UI)"
  type        = string
  default     = "aks-executor-pool"
}

# Container Registry Configuration
variable "container_registry_url" {
  description = "Container registry URL (e.g., customername.azurecr.io for ACR)"
  type        = string
}

variable "container_registry_username" {
  description = "Container registry username (not required if using Workload Identity with ACR)"
  type        = string
  default     = ""
}

variable "container_registry_password" {
  description = "Container registry password or service account key (not required if using Workload Identity with ACR)"
  type        = string
  sensitive   = true
  default     = ""
}

# Azure Container Registry (ACR) Configuration for Workload Identity
variable "acr_name" {
  description = "Azure Container Registry name (required if using Workload Identity for ACR access)"
  type        = string
  default     = ""
}

variable "acr_resource_group_name" {
  description = "Resource group name where ACR is located (defaults to AKS resource group if not specified)"
  type        = string
  default     = ""
}

# Image Configuration
variable "image_repository" {
  description = "DataHub executor image repository (e.g., customername.azurecr.io/datahub-executor)"
  type        = string
  default     = "docker.datahub.com/enterprise/datahub-executor"
}

variable "image_tag" {
  description = "DataHub executor image tag"
  type        = string
  default     = "v0.3.13-acryl"
}

# Executor Configuration
variable "replica_count" {
  description = "Number of executor replicas for horizontal scaling"
  type        = number
  default     = 1
  
  validation {
    condition     = var.replica_count > 0
    error_message = "Replica count must be greater than 0."
  }
}

variable "ingestion_max_workers" {
  description = "Maximum number of concurrent ingestion workers per pod"
  type        = number
  default     = 2
}

variable "ingestion_signal_poll_interval" {
  description = "Signal polling interval for ingestion workers (seconds)"
  type        = number
  default     = 5
}

variable "monitors_max_workers" {
  description = "Maximum number of concurrent monitor workers per pod"
  type        = number
  default     = 2
}

# Resource Configuration
variable "resources_requests_memory" {
  description = "Memory requests for executor pods"
  type        = string
  default     = "512Mi"
}

variable "resources_requests_cpu" {
  description = "CPU requests for executor pods"
  type        = string
  default     = "250m"
}

variable "resources_limits_memory" {
  description = "Memory limits for executor pods"
  type        = string
  default     = "1Gi"
}

variable "resources_limits_cpu" {
  description = "CPU limits for executor pods"
  type        = string
  default     = "500m"
}

# AKS Configuration
variable "create_namespace" {
  description = "Whether to create the Kubernetes namespace"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable Azure AD Workload Identity for the service account (AKS 1.24+)"
  type        = bool
  default     = false
}

variable "azure_identity_name" {
  description = "Name of the Azure User Assigned Identity for Workload Identity (if enabled)"
  type        = string
  default     = "datahub-executor-identity"
}

# Network Configuration for Locked-Down Environments
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
  description = "Comma-separated list of hosts that should bypass the proxy (e.g., localhost,127.0.0.1,.svc,.cluster.local)"
  type        = string
  default     = "localhost,127.0.0.1,.svc,.cluster.local"
}

# Helm Chart Configuration
variable "helm_chart_path" {
  description = "Path to the local Helm chart"
  type        = string
  default     = "./datahub-executor-helm/charts/datahub-executor-worker"
}

variable "helm_release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "datahub-executor"
}

# Additional Configuration
variable "pod_annotations" {
  description = "Additional annotations for executor pods"
  type        = map(string)
  default     = {}
}

variable "node_selector" {
  description = "Node selector for executor pods (e.g., {\"agentpool\": \"datahub\"})"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for executor pods to schedule on tainted nodes"
  type = list(object({
    key      = optional(string)
    operator = optional(string, "Equal")
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}

variable "enable_debug" {
  description = "Enable debug mode for DataHub executor (sets DATAHUB_DEBUG=true)"
  type        = bool
  default     = false
}

# Custom Transformer Configuration
variable "custom_transformers_path" {
  description = "Path to the directory containing custom transformers. Set to empty string to disable custom transformers."
  type        = string
  default     = ""
}

# Note: Custom transformers are automatically enabled when custom_transformers_path is set to a non-empty value

