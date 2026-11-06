# NOTE: confirm DATAHUB_SQL_SETUP_ENABLED and the other environment variable names below against the
# "Docker Images" reference for the DataHub version you are deploying.

resource "aws_ecs_task_definition" "system_update" {
  family                   = "${var.name}-system-update"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.gms_cpu
  memory                   = var.gms_memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn             = var.gms_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "system-update"
      image     = var.upgrade_image
      command = ["-u", "SystemUpdate"]
      essential = true

      environment = [
        { name = "EBEAN_DATASOURCE_USERNAME", value = var.db_username },
        { name = "EBEAN_DATASOURCE_HOST", value = "${var.rds_address}:${var.rds_port}" },
        { name = "EBEAN_DATASOURCE_URL", value = "jdbc:mysql://${var.rds_address}:${var.rds_port}/${var.db_name}" },
        { name = "EBEAN_DATASOURCE_DRIVER", value = "com.mysql.cj.jdbc.Driver" },

        { name = "KAFKA_BOOTSTRAP_SERVER", value = var.msk_bootstrap_brokers_tls },
        { name = "SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL", value = "SSL" },
        { name = "SCHEMA_REGISTRY_TYPE", value = "INTERNAL"}, 
        { name = "KAFKA_SCHEMAREGISTRY_URL", value = "http://${var.gms_cloudmap_dns}:8080/schema-registry/api/"},

        { name = "ELASTICSEARCH_HOST", value = var.opensearch_endpoint },
        { name = "ELASTICSEARCH_PORT", value = "443" },
        { name = "ELASTICSEARCH_USE_SSL", value = "true" },
        { name = "OPENSEARCH_USE_AWS_IAM_AUTH", value = "true" },
        { name = "AWS_REGION", value = var.aws_region },

        { name = "DATAHUB_SQL_SETUP_ENABLED", value = "true" },
      ]

      secrets = [
        { name = "EBEAN_DATASOURCE_PASSWORD", valueFrom = "${var.datahub_secret_arn}:db_password::" },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.system_update.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "system-update"
        }
      }
    }
  ])

  tags = { Name = "${var.name}-system-update" }
}
