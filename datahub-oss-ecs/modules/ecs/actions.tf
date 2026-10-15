# Pulls the custom image built per "Customize the Actions image" (executor.yaml,
# doc_propagation_action.yaml, and the Kafka CA certificate baked in) from the ECR repository the
# ecr module creates — build and push that image before this service can start.

resource "aws_ecs_task_definition" "actions" {
  family                   = "${var.name}-actions"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.actions_cpu
  memory                   = var.actions_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn             = var.actions_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "actions"
      image     = var.actions_image
      essential = true

      environment = [
        { name = "DATAHUB_GMS_HOST", value = var.gms_cloudmap_dns },
        { name = "DATAHUB_GMS_PORT", value = tostring(var.gms_port) },
        { name = "DATAHUB_SYSTEM_CLIENT_ID", value = var.datahub_system_client_id },
        { name = "SCHEMA_REGISTRY_URL", value = "http://${var.gms_cloudmap_dns}:8080/schema-registry/api/"},
        {name = "SCHEMA_REGISTRY_TYPE", value = "INTERNAL"},
        { name = "KAFKA_BOOTSTRAP_SERVER", value = var.msk_bootstrap_brokers_tls },
        { name = "KAFKA_PROPERTIES_SECURITY_PROTOCOL", value = "SSL" },
      ]

      secrets = [
        { name = "DATAHUB_SYSTEM_CLIENT_SECRET", valueFrom = var.datahub_secret_arn },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.actions.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "actions"
        }
      }
    }
  ])

  tags = { Name = "${var.name}-actions" }
}

resource "aws_ecs_service" "actions" {
  name            = "${var.name}-actions"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.actions.arn
  desired_count   = var.actions_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.actions_sg_id]
    assign_public_ip = false
  }

  tags = { Name = "${var.name}-actions" }
}
