# Main Terraform configuration for DataHub Remote Executor on AKS

# Configure the Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Data source to get AKS cluster information
data "azurerm_kubernetes_cluster" "primary" {
  name                = var.aks_cluster_name
  resource_group_name = var.resource_group_name
}

# Configure the Kubernetes Provider
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.primary.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.cluster_ca_certificate)
}

# Configure the Helm Provider
provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.primary.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config.0.cluster_ca_certificate)
  }
}

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

# Create Azure User Assigned Identity for Workload Identity (if enabled)
resource "azurerm_user_assigned_identity" "datahub_executor" {
  count = var.enable_workload_identity ? 1 : 0
  
  name                = var.azure_identity_name
  resource_group_name = var.resource_group_name
  location            = data.azurerm_kubernetes_cluster.primary.location
  
  tags = {
    environment = var.environment
    app         = "datahub-executor"
  }
}

# Federated credential for Workload Identity (if enabled)
resource "azurerm_federated_identity_credential" "datahub_executor" {
  count = var.enable_workload_identity ? 1 : 0
  
  name                = "${var.azure_identity_name}-federated"
  resource_group_name = var.resource_group_name
  parent_id           = azurerm_user_assigned_identity.datahub_executor[0].id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azurerm_kubernetes_cluster.primary.oidc_issuer_url
  subject             = "system:serviceaccount:${var.kubernetes_namespace}:datahub-executor-sa"
}

# Grant ACR pull role to managed identity (if enabled and ACR name provided)
resource "azurerm_role_assignment" "acr_pull" {
  count = var.enable_workload_identity && var.acr_name != "" ? 1 : 0
  
  scope                = "/subscriptions/${var.subscription_id}/resourceGroups/${local.acr_resource_group}/providers/Microsoft.ContainerRegistry/registries/${var.acr_name}"
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.datahub_executor[0].principal_id
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

# Create Kubernetes secret for container registry credentials (if not using managed identity)
resource "kubernetes_secret" "container_registry" {
  count      = var.enable_workload_identity ? 0 : 1
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

# Local variables
locals {
  # Default ACR resource group to AKS resource group if not specified
  acr_resource_group = var.acr_resource_group_name != "" ? var.acr_resource_group_name : var.resource_group_name
  
  # Enable custom transformers if path is provided
  enable_custom_transformers = var.custom_transformers_path != "" && var.custom_transformers_path != null
}

# Create ConfigMap for custom transformers (single configmap with all files)

resource "kubernetes_config_map" "custom_transformers" {
  count      = local.enable_custom_transformers ? 1 : 0
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
  name      = var.helm_release_name
  chart     = var.helm_chart_path
  namespace = var.kubernetes_namespace
  
  # Force recreation if namespace is created
  depends_on = [
    kubernetes_secret.datahub_access_token,
    kubernetes_secret.container_registry,
    kubernetes_config_map.custom_transformers,
    azurerm_role_assignment.acr_pull
  ]
  
  values = [
    templatefile("${path.module}/helm-values.yaml.tpl", {
      datahub_gms_url                   = var.datahub_gms_url
      datahub_secret_name               = kubernetes_secret.datahub_access_token.metadata[0].name
      executor_pool_id                  = var.datahub_remote_executor_pool_id
      ingestion_max_workers             = var.ingestion_max_workers
      ingestion_signal_poll_interval    = var.ingestion_signal_poll_interval
      monitors_max_workers              = var.monitors_max_workers
      replica_count                     = var.replica_count
      image_repository                  = var.image_repository
      image_tag                         = var.image_tag
      registry_secret_name              = var.enable_workload_identity ? "" : kubernetes_secret.container_registry[0].metadata[0].name
      resources_requests_memory         = var.resources_requests_memory
      resources_requests_cpu            = var.resources_requests_cpu
      resources_limits_memory           = var.resources_limits_memory
      resources_limits_cpu              = var.resources_limits_cpu
      enable_workload_identity          = var.enable_workload_identity
      azure_client_id                   = var.enable_workload_identity ? azurerm_user_assigned_identity.datahub_executor[0].client_id : ""
      pod_annotations                   = var.pod_annotations
      environment                       = var.environment
      node_selector                     = var.node_selector
      tolerations                       = var.tolerations
      enable_debug                      = var.enable_debug
      enable_custom_transformers        = local.enable_custom_transformers
      custom_transformers_configmap     = local.enable_custom_transformers ? kubernetes_config_map.custom_transformers[0].metadata[0].name : ""
      http_proxy                        = var.http_proxy
      https_proxy                       = var.https_proxy
      no_proxy                          = var.no_proxy
    })
  ]
}

