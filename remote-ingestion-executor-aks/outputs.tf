# Output values for DataHub Remote Executor deployment on AKS

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = var.aks_cluster_name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = var.resource_group_name
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

output "azure_identity_client_id" {
  description = "Client ID of the Azure User Assigned Identity (if Workload Identity is enabled)"
  value       = var.enable_workload_identity ? azurerm_user_assigned_identity.datahub_executor[0].client_id : null
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
  description = "Name of the Kubernetes secret for container registry credentials (null if using Workload Identity)"
  value       = var.enable_workload_identity ? null : kubernetes_secret.container_registry[0].metadata[0].name
}

# Connection information for kubectl
output "kubectl_config_command" {
  description = "Command to configure kubectl for the AKS cluster"
  value       = "az aks get-credentials --name ${var.aks_cluster_name} --resource-group ${var.resource_group_name}"
}

# Useful debugging commands
output "debugging_commands" {
  description = "Useful commands for debugging the deployment"
  value = {
    check_pods                = "kubectl get pods -n ${var.kubernetes_namespace}"
    check_logs                = "kubectl logs -n ${var.kubernetes_namespace} -l app.kubernetes.io/name=datahub-executor-worker --tail=100"
    check_logs_follow         = "kubectl logs -n ${var.kubernetes_namespace} -l app.kubernetes.io/name=datahub-executor-worker -f"
    check_secrets             = "kubectl get secrets -n ${var.kubernetes_namespace}"
    check_helm_release        = "helm list -n ${var.kubernetes_namespace}"
    describe_deployment       = "kubectl describe deployment ${var.helm_release_name}-datahub-executor-worker -n ${var.kubernetes_namespace}"
    check_pod_events          = "kubectl get events -n ${var.kubernetes_namespace} --sort-by='.lastTimestamp'"
    test_gms_connectivity     = "kubectl run -n ${var.kubernetes_namespace} -it --rm debug --image=curlimages/curl --restart=Never -- curl -v ${var.datahub_gms_url}/health"
    test_sqs_connectivity     = "kubectl run -n ${var.kubernetes_namespace} -it --rm debug --image=curlimages/curl --restart=Never -- curl -v https://sqs.us-west-2.amazonaws.com"
    exec_into_pod             = "kubectl exec -n ${var.kubernetes_namespace} -it $(kubectl get pods -n ${var.kubernetes_namespace} -l app.kubernetes.io/name=datahub-executor-worker -o jsonpath='{.items[0].metadata.name}') -- /bin/bash"
  }
}

# Network configuration summary (for locked-down environments)
output "network_requirements" {
  description = "Summary of network connectivity requirements"
  value = {
    description = "Outbound HTTPS (443) connectivity required to the following endpoints:"
    endpoints = [
      "DataHub GMS: ${var.datahub_gms_url} (GMS handles AWS STS calls on behalf of executor)",
      "AWS SQS: sqs.<region>.amazonaws.com (e.g., sqs.us-west-2.amazonaws.com)",
      "Container Registry: ${var.container_registry_url}"
    ]
    note            = "Executor does NOT need direct access to AWS STS - GMS handles credential operations"
    proxy_configured = var.http_proxy != "" || var.https_proxy != "" ? "Yes (HTTP_PROXY=${var.http_proxy}, HTTPS_PROXY=${var.https_proxy})" : "No"
  }
}

