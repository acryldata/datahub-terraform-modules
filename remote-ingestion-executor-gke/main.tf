# Main Terraform configuration for DataHub Remote Executor on GKE

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Data source to get GKE cluster information
data "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  project  = var.project_id
}

# Configure the Kubernetes Provider
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
}

# Configure the Helm Provider
provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth.0.cluster_ca_certificate)
  }
}

# Get Google client configuration for authentication
data "google_client_config" "default" {}

# Create namespace if specified
resource "kubernetes_namespace" "datahub_executor" {
  count = var.create_namespace ? 1 : 0
  
  metadata {
    name = var.kubernetes_namespace
    
    labels = {
      environment = var.environment
      app         = "datahub-executor"
    }
  }
}

# Create GCP Service Account for Workload Identity (if enabled)
resource "google_service_account" "datahub_executor" {
  count = var.enable_workload_identity ? 1 : 0
  
  account_id   = var.gcp_service_account_name
  display_name = "DataHub Executor Service Account"
  description  = "Service account for DataHub Remote Executor with Workload Identity"
  project      = var.project_id
}

# Bind GCP Service Account to Kubernetes Service Account (if Workload Identity is enabled)
resource "google_service_account_iam_binding" "workload_identity" {
  count = var.enable_workload_identity ? 1 : 0
  
  service_account_id = google_service_account.datahub_executor[0].name
  role               = "roles/iam.workloadIdentityUser"
  
  members = [
    "serviceAccount:${var.project_id}.svc.id.goog[${var.kubernetes_namespace}/datahub-executor-sa]"
  ]
}

# Create Kubernetes secret for DataHub access token
resource "kubernetes_secret" "datahub_access_token" {
  depends_on = [kubernetes_namespace.datahub_executor]
  
  metadata {
    name      = "datahub-access-token"
    namespace = var.kubernetes_namespace
    
    labels = {
      environment = var.environment
      app         = "datahub-executor"
    }
  }
  
  data = {
    token = var.datahub_access_token
  }
  
  type = "Opaque"
}

# Create Kubernetes secret for container registry credentials
resource "kubernetes_secret" "container_registry" {
  depends_on = [kubernetes_namespace.datahub_executor]
  
  metadata {
    name      = "datahub-docker-registry"
    namespace = var.kubernetes_namespace
    
    labels = {
      environment = var.environment
      app         = "datahub-executor"
    }
  }
  
  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        (var.container_registry_url) = {
          username = var.container_registry_username
          password = var.container_registry_password
          auth     = base64encode("${var.container_registry_username}:${var.container_registry_password}")
        }
      }
    })
  }
  
  type = "kubernetes.io/dockerconfigjson"
}

# Create ConfigMap for custom transformers (single configmap with all files)
locals {
  enable_custom_transformers = var.custom_transformers_path != "" && var.custom_transformers_path != null
}

resource "kubernetes_config_map" "custom_transformers" {
  count = local.enable_custom_transformers ? 1 : 0
  depends_on = [kubernetes_namespace.datahub_executor]
  
  metadata {
    name      = "custom-transformers"
    namespace = var.kubernetes_namespace
    
    labels = {
      environment = var.environment
      app         = "datahub-executor"
    }
  }
  
  data = {
    for filename in fileset("${path.module}/${var.custom_transformers_path}", "*") :
    filename => file("${path.module}/${var.custom_transformers_path}/${filename}")
    if !startswith(filename, ".") # Skip hidden files like .DS_Store
  }
}

# Deploy DataHub Executor using Helm
resource "helm_release" "datahub_executor" {
  name       = var.helm_release_name
  chart      = var.helm_chart_path
  namespace  = var.kubernetes_namespace
  
  # Force recreation if namespace is created
  depends_on = [
    kubernetes_secret.datahub_access_token,
    kubernetes_secret.container_registry,
    kubernetes_config_map.custom_transformers
  ]
  
  values = [
    templatefile("${path.module}/helm-values.yaml.tpl", {
      datahub_gms_url                   = var.datahub_gms_url
      datahub_secret_name              = kubernetes_secret.datahub_access_token.metadata[0].name
      executor_pool_id                 = var.datahub_remote_executor_pool_id
      ingestion_max_workers            = var.ingestion_max_workers
      ingestion_signal_poll_interval   = var.ingestion_signal_poll_interval
      monitors_max_workers             = var.monitors_max_workers
      replica_count                    = var.replica_count
      image_repository                 = var.image_repository
      image_tag                        = var.image_tag
      registry_secret_name             = kubernetes_secret.container_registry.metadata[0].name
      resources_requests_memory        = var.resources_requests_memory
      resources_requests_cpu           = var.resources_requests_cpu
      resources_limits_memory          = var.resources_limits_memory
      resources_limits_cpu             = var.resources_limits_cpu
      enable_workload_identity         = var.enable_workload_identity
      gcp_service_account_email        = var.enable_workload_identity ? google_service_account.datahub_executor[0].email : ""
      pod_annotations                  = var.pod_annotations
      environment                      = var.environment
      node_selector                    = var.node_selector
      tolerations                      = var.tolerations
      enable_debug                     = var.enable_debug
      enable_custom_transformers       = local.enable_custom_transformers
      custom_transformers_configmap    = local.enable_custom_transformers ? kubernetes_config_map.custom_transformers[0].metadata[0].name : ""
    })
  ]
}
