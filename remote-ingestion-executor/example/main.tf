locals {
  datahub = {
    url       = "https://<your-company>.acryl.io/gms"
  }
}

module "example" {
  source = "../"

  cluster_name = "remote-ingestion-executor-example"

  create_tasks_iam_role = true

  create_task_exec_iam_role = true
  task_exec_secret_arns = [
    aws_secretsmanager_secret.datahub_access_token.arn,
  ]

  datahub = local.datahub

  secrets = [
    {
      name      = "DATAHUB_GMS_TOKEN"
      valueFrom = aws_secretsmanager_secret.datahub_access_token.arn
    },
  ]

  subnet_ids = ["subnet-XXX"]

  assign_public_ip = true

  security_group_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    },
  }
}

resource "aws_secretsmanager_secret" "datahub_access_token" {
  name = "datahub_access_token"
}

resource "aws_secretsmanager_secret_version" "service_user" {
  secret_id     = aws_secretsmanager_secret.datahub_access_token.id
  secret_string = "XXX"
}
