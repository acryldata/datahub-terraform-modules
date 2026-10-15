output "frontend_repository_url" {
  value = aws_ecr_repository.frontend.repository_url
}

output "frontend_repository_name" {
  value = aws_ecr_repository.frontend.name
}

output "actions_repository_url" {
  value = aws_ecr_repository.actions.repository_url
}

output "actions_repository_name" {
  value = aws_ecr_repository.actions.name
}
