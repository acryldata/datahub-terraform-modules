output "private_subnet_ids" {
  description = "IDs of the private subnets used for ECS tasks"
  value       = var.private_subnet_ids
}

output "security_group_id" {
  description = "ID of the security group for ECS tasks"
  value       = aws_security_group.ecs_instances.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ecs_instance.id
}
