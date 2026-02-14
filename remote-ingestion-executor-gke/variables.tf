# Terraform variables for DataHub Remote Executor deployment on GKE

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "The GCP region for the GKE cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name of the existing GKE cluster"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for DataHub executor deployment"
  type        = string
  default     = "datahub-executor"
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
  description = "DataHub GMS endpoint URL"
  type        = string
}

variable "datahub_access_token" {
  description = "DataHub access token for authentication"
  type        = string
  sensitive   = true
}

variable "datahub_remote_executor_pool_id" {
  description = "DataHub executor pool ID"
  type        = string
  default     = "gke-executor-pool"
}

# Container Registry Configuration
variable "container_registry_url" {
  description = "Container registry URL (e.g., gcr.io/project-id, us-docker.pkg.dev/project-id/repo)"
  type        = string
  default     = "docker.datahub.com/enterprise"
}

variable "container_registry_username" {
  description = "Container registry username"
  type        = string
  default     = "_json_key"
}

variable "container_registry_password" {
  description = "Container registry password or service account key"
  type        = string
  sensitive   = true
}

# Image Configuration
variable "image_repository" {
  description = "DataHub executor image repository"
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
  description = "Number of executor replicas"
  type        = number
  default     = 1
}

variable "ingestion_max_workers" {
  description = "Maximum number of ingestion workers"
  type        = number
  default     = 2
}

variable "ingestion_signal_poll_interval" {
  description = "Signal polling interval for ingestion workers (seconds)"
  type        = number
  default     = 5
}

variable "monitors_max_workers" {
  description = "Maximum number of monitor workers"
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

# GKE Configuration
variable "create_namespace" {
  description = "Whether to create the Kubernetes namespace"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for the service account"
  type        = bool
  default     = false
}

variable "gcp_service_account_name" {
  description = "Name of the GCP service account for Workload Identity (if enabled)"
  type        = string
  default     = "datahub-executor-sa"
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
  description = "Node selector for executor pods"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Tolerations for executor pods"
  type = list(object({
    key      = optional(string)
    operator = optional(string, "Equal")
    value    = optional(string)
    effect   = optional(string)
  }))
  default = []
}

variable "enable_debug" {
  description = "Enable debug mode for DataHub executor"
  type        = bool
  default     = false
}

# Custom Transformer Configuration
variable "custom_transformers_path" {
  description = "Path to the directory containing custom transformers. Set to empty string to disable custom transformers."
  type        = string
  default     = "sample/transformers"
}

# Note: Custom transformers are automatically enabled when custom_transformers_path is set to a non-empty value
