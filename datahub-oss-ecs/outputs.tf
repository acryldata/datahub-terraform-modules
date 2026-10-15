output "vpc_id" {
  description = "ID of the VPC created for this deployment."
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB only)."
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs (ECS tasks, RDS, MSK, OpenSearch)."
  value       = module.networking.private_subnet_ids
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = module.ecs.cluster_name
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB. Point your own DNS at this if not using route53_zone_id/dns_name."
  value       = module.load_balancer.alb_dns_name
}

output "datahub_url" {
  description = "URL to reach DataHub, if a Route 53 record was created."
  value       = module.load_balancer.datahub_url
}

output "gms_cloudmap_dns" {
  description = "Internal Cloud Map DNS name used by Frontend/Actions to reach GMS (DATAHUB_GMS_HOST)."
  value       = module.service_discovery.gms_dns_name
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint (host:port)."
  value       = module.data_stores.rds_endpoint
}

output "msk_bootstrap_brokers_tls" {
  description = "MSK TLS bootstrap broker string (KAFKA_BOOTSTRAP_SERVER)."
  value       = module.data_stores.msk_bootstrap_brokers_tls
}

output "opensearch_endpoint" {
  description = "OpenSearch domain endpoint."
  value       = module.data_stores.opensearch_endpoint
}

output "frontend_ecr_repository_url" {
  description = "Push the custom Frontend image before deploying the Frontend service."
  value       = module.ecr.frontend_repository_url
}

output "actions_ecr_repository_url" {
  description = "Push the custom Actions image before deploying the Actions service."
  value       = module.ecr.actions_repository_url
}

output "datahub_secret_arn" {
  description = "Secrets Manager ARN holding Datahub secrets."
  value       = module.secrets.datahub_secret_arn
}
