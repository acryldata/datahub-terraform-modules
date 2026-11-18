# Pulls the custom image built per "Customize the Frontend image" from the ECR repository the ecr
# module creates — build and push that image before this service can start.

resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.name}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn             = var.frontend_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = var.frontend_image
      essential = true

      portMappings = [
        {
          containerPort = var.frontend_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "DATAHUB_GMS_HOST", value = var.gms_cloudmap_dns },
        { name = "DATAHUB_GMS_PORT", value = tostring(var.gms_port) },
        { name = "METADATA_SERVICE_AUTH_ENABLED", value = tostring(var.metadata_service_auth_enabled) },
        { name = "DATAHUB_SYSTEM_CLIENT_ID", value = var.datahub_system_client_id },
      ]

      secrets = [
        { name = "DATAHUB_SYSTEM_CLIENT_SECRET", valueFrom = "${var.datahub_secret_arn}:datahub_system_client_secret::" },
        { name = "DATAHUB_SECRET", valueFrom = "${var.datahub_secret_arn}:datahub_secret::" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])

  tags = { Name = "${var.name}-frontend" }
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.name}-frontend"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.frontend_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name    = "frontend"
    container_port    = var.frontend_port
  }

  tags = { Name = "${var.name}-frontend" }
}
