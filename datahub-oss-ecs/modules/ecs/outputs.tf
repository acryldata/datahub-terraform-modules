output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "gms_service_name" {
  value = aws_ecs_service.gms.name
}

output "frontend_service_name" {
  value = aws_ecs_service.frontend.name
}

output "actions_service_name" {
  value = aws_ecs_service.actions.name
}
