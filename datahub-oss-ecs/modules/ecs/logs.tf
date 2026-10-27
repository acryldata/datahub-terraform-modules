resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.name}/frontend"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "gms" {
  name              = "/ecs/${var.name}/gms"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "actions" {
  name              = "/ecs/${var.name}/actions"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "system_update" {
  name              = "/ecs/${var.name}/system-update"
  retention_in_days = 30
}
