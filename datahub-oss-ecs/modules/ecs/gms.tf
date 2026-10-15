# NOTE: the exact DataHub environment variable names below (EBEAN_*, ELASTICSEARCH_*, KAFKA_*, etc.)
# reflect commonly used defaults as of this writing. Confirm them against the current
# "Deployment Environment Variables" and "Kafka Configuration" docs for the DataHub version you are
# deploying before relying on this in production.

resource "aws_ecs_task_definition" "gms" {
  family                   = "${var.name}-gms"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.gms_cpu
  memory                   = var.gms_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn             = var.gms_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "gms"
      image     = var.gms_image
      essential = true

      portMappings = [
        {
          containerPort = var.gms_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "EBEAN_DATASOURCE_USERNAME", value = var.db_username },
        { name = "EBEAN_DATASOURCE_HOST", value = "${var.rds_address}:${var.rds_port}" },
        { name = "EBEAN_DATASOURCE_URL", value = "jdbc:mysql://${var.rds_address}:${var.rds_port}/${var.db_name}" },
        { name = "EBEAN_DATASOURCE_DRIVER", value = "com.mysql.cj.jdbc.Driver" },

        { name = "KAFKA_BOOTSTRAP_SERVER", value = var.msk_bootstrap_brokers_tls },
        { name = "SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL", value = "SSL" },
        { name = "SCHEMA_REGISTRY_TYPE", value = "INTERNAL" },
        { name = "KAFKA_SCHEMAREGISTRY_URL", value = "http://localhost:${var.gms_port}/schema-registry/api/" },

        { name = "ELASTICSEARCH_HOST", value = var.opensearch_endpoint },
        { name = "ELASTICSEARCH_PORT", value = "443" },
        { name = "ELASTICSEARCH_USE_SSL", value = "true" },
        { name = "ELASTICSEARCH_SHIM_ENGINE_TYPE", value = "OPENSEARCH_2" },
        { name = "ELASTICSEARCH_IMPLEMENTATION", value = "opensearch"},
        { name = "OPENSEARCH_USE_AWS_IAM_AUTH", value = "true" },
        { name = "AWS_REGION", value = var.aws_region },

        { name = "METADATA_SERVICE_AUTH_ENABLED", value = tostring(var.metadata_service_auth_enabled) },
        { name = "DATAHUB_SYSTEM_CLIENT_ID", value = var.datahub_system_client_id },

        { name = "MAE_CONSUMER_ENABLED", value = "true" },
        { name = "MCE_CONSUMER_ENABLED", value = "true" },
        { name = "SEARCH_SERVICE_ENABLE_CACHE", value = "true" },
      ]

      secrets = [
        { name = "EBEAN_DATASOURCE_PASSWORD", valueFrom = var.datahub_secret_arn },
        { name = "DATAHUB_SYSTEM_CLIENT_SECRET", valueFrom = var.datahub_secret_arn },
        { name = "DATAHUB_TOKEN_SERVICE_SIGNING_KEY", valueFrom = var.datahub_secret_arn },
        { name = "DATAHUB_TOKEN_SERVICE_SALT", valueFrom = var.datahub_secret_arn },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.gms.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "gms"
        }
      }
    }
  ])

  tags = { Name = "${var.name}-gms" }
}

resource "aws_ecs_service" "gms" {
  name            = "${var.name}-gms"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.gms.arn
  desired_count   = var.gms_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.gms_sg_id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = var.gms_service_registry_arn
  }

  tags = { Name = "${var.name}-gms" }
}
