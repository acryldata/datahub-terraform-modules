# Deploy DataHub Remote Ingestion Executor on AWS ECS Fargate
terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Deploy the DataHub Remote Ingestion Executor
module "datahub_remote_executor" {
  source = "../"

  cluster_name = "datahub-remote-executor"

  datahub = {
    url                              = "https://test-environment.acryl.io/gms"
    executor_pool_id                 = "ecs-executor-pool"
    executor_ingestions_workers      = 4
    executor_monitors_workers        = 10
    executor_ingestions_poll_interval = 5
  }

  service_name   = "datahub-remote-executor"
  desired_count  = 1

  cpu    = 1024  # 1 vCPU
  memory = 2048  # 2 GB

  subnet_ids = [
    "subnet-07da46d0210baeddb",  # us-west-2c
    "subnet-0149aee6b01a8068c",  # us-west-2d
  ]

  assign_public_ip = true

  security_group_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  create_tasks_iam_role     = true
  create_task_exec_iam_role = true

  task_exec_secret_arns = [
    "arn:aws:secretsmanager:us-west-2:863541928889:secret:datahub-access-token-xw7EfB"
  ]

  secrets = [
    {
      name      = "DATAHUB_GMS_TOKEN"
      valueFrom = "arn:aws:secretsmanager:us-west-2:863541928889:secret:datahub-access-token-xw7EfB"
    }
  ]

  enable_cloudwatch_logging   = true
  create_cloudwatch_log_group = true
  enable_execute_command      = true

  tags = {
    Environment = "dev"
    Project     = "datahub-remote-executor"
    ManagedBy   = "terraform"
  }
}

# Output important information
output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.datahub_remote_executor.cluster_name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.datahub_remote_executor.cluster_arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = module.datahub_remote_executor.service_name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = module.datahub_remote_executor.task_definition_arn
}
