output "execution_role_arn" {
  value = aws_iam_role.ecs_task_execution.arn
}

output "gms_task_role_arn" {
  value = aws_iam_role.gms_task.arn
}

output "gms_task_role_name" {
  value = aws_iam_role.gms_task.name
}

output "frontend_task_role_arn" {
  value = aws_iam_role.frontend_task.arn
}

output "actions_task_role_arn" {
  value = aws_iam_role.actions_task.arn
}
