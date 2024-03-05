module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.4.0"

  cluster_name          = var.cluster_name
  cluster_configuration = var.cluster_configuration

  tags = var.tags
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.4.0"

  cluster_arn = module.ecs_cluster.arn
  name        = var.service_name

  create_tasks_iam_role   = var.create_tasks_iam_role
  tasks_iam_role_arn      = var.tasks_iam_role_arn
  tasks_iam_role_name     = var.tasks_iam_role_name
  tasks_iam_role_policies = var.tasks_iam_role_policies

  create_task_exec_iam_role = var.create_task_exec_iam_role
  task_exec_iam_role_name   = var.task_exec_iam_role_name

  create_task_exec_policy     = var.create_task_exec_policy
  task_exec_iam_role_policies = var.task_exec_iam_role_policies
  task_exec_ssm_param_arns    = var.task_exec_ssm_param_arns
  task_exec_secret_arns       = var.task_exec_secret_arns

  cpu           = var.cpu
  memory        = var.memory
  desired_count = var.desired_count
  launch_type   = "FARGATE"

  enable_execute_command   = var.enable_execute_command
  requires_compatibilities = var.requires_compatibilities

  subnet_ids           = var.subnet_ids
  security_group_ids   = var.security_group_ids
  security_group_rules = var.security_group_rules
  assign_public_ip     = var.assign_public_ip

  container_definitions = {
    dh-sqs-remote-executor = {
      cpu    = var.cpu
      memory = var.memory
      image  = format("%s:%s", var.datahub.image, var.datahub.image_tag)

      network_mode = var.network_mode

      port_mappings = [
        {
          containerPort = 80
        }
      ]

      enable_cloudwatch_logging   = var.enable_cloudwatch_logging
      create_cloudwatch_log_group = var.create_cloudwatch_log_group
      log_configuration           = var.log_configuration
      readonly_root_filesystem    = false

      secrets = var.secrets

      environment = concat(var.environment, [
        {
          name  = "DATAHUB_BASE_URL"
          value = var.datahub.url
        },
        {
          name  = "AWS_COMMAND_QUEUE_URL"
          value = var.datahub.queue_url
        },
        {
          name  = "EXECUTOR_ID"
          value = var.datahub.executor_id
        },
        {
          name  = "AWS_REGION"
          value = local.queue_region
        },
      ])
    }
  }

  tags = var.tags
}
