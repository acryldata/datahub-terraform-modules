# Output values for DataHub Remote Executor deployment

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = var.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the GKE cluster"
  value       = data.google_container_cluster.primary.endpoint
  sensitive   = true
}

output "namespace" {
  description = "Kubernetes namespace where DataHub executor is deployed"
  value       = var.kubernetes_namespace
}

output "helm_release_name" {
  description = "Name of the Helm release"
  value       = helm_release.datahub_executor.name
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.datahub_executor.status
}

output "datahub_gms_url" {
  description = "DataHub GMS endpoint URL"
  value       = var.datahub_gms_url
}

output "datahub_remote_executor_pool_id" {
  description = "DataHub executor pool ID"
  value       = var.datahub_remote_executor_pool_id
}

output "image_repository" {
  description = "DataHub executor image repository"
  value       = var.image_repository
}

output "image_tag" {
  description = "DataHub executor image tag"
  value       = var.image_tag
}

output "replica_count" {
  description = "Number of executor replicas"
  value       = var.replica_count
}

output "environment" {
  description = "Deployment environment"
  value       = var.environment
}

output "gcp_service_account_email" {
  description = "Email of the GCP service account (if Workload Identity is enabled)"
  value       = var.enable_workload_identity ? google_service_account.datahub_executor[0].email : null
}

output "kubernetes_service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = "datahub-executor-sa"
}

output "datahub_access_token_secret_name" {
  description = "Name of the Kubernetes secret containing DataHub access token"
  value       = kubernetes_secret.datahub_access_token.metadata[0].name
}

output "container_registry_secret_name" {
  description = "Name of the Kubernetes secret for container registry credentials"
  value       = kubernetes_secret.container_registry.metadata[0].name
}

# Connection information for kubectl
output "kubectl_config_command" {
  description = "Command to configure kubectl for the cluster"
  value       = "gcloud container clusters get-credentials ${var.cluster_name} --region ${var.region} --project ${var.project_id}"
}

# Useful debugging commands
output "debugging_commands" {
  description = "Useful commands for debugging the deployment"
  value = {
    check_pods           = "kubectl get pods -n ${var.kubernetes_namespace}"
    check_logs          = "kubectl logs -n ${var.kubernetes_namespace} -l app.kubernetes.io/name=datahub-executor-worker --tail=100"
    check_secrets       = "kubectl get secrets -n ${var.kubernetes_namespace}"
    check_helm_release  = "helm list -n ${var.kubernetes_namespace}"
    describe_deployment = "kubectl describe deployment ${var.helm_release_name}-datahub-executor-worker -n ${var.kubernetes_namespace}"
  }
}
