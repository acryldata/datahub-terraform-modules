# Outputs for DataHub Remote Ingestion Executor

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = module.ecs_service.name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = module.ecs_service.task_definition_arn
}

# EC2-specific outputs (only populated when launch_type = "EC2")
output "private_subnet_ids" {
  description = "IDs of the private subnets used (EC2 only)"
  value       = length(module.ec2_infrastructure) > 0 ? module.ec2_infrastructure[0].private_subnet_ids : []
}

output "instance_id" {
  description = "ID of the EC2 instance (EC2 only)"
  value       = length(module.ec2_infrastructure) > 0 ? module.ec2_infrastructure[0].instance_id : null
}
