# EC2 Infrastructure Module (only created when launch_type is EC2)
module "ec2_infrastructure" {
  count  = var.launch_type == "EC2" ? 1 : 0
  source = "./modules/ec2-infrastructure"

  cluster_name       = var.cluster_name
  private_subnet_ids = var.ec2_config.private_subnet_ids
  instance_type      = var.ec2_config.instance_type

  tags = var.tags
}

module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "5.9.2"

  cluster_name          = var.cluster_name
  cluster_configuration = var.cluster_configuration

  tags = var.tags
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.9.2"

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
  launch_type   = var.launch_type

  enable_execute_command   = var.enable_execute_command

  # Use EC2 infrastructure outputs for EC2 launch type, otherwise use provided values
  subnet_ids = var.launch_type == "EC2" ? (
    length(module.ec2_infrastructure) > 0 ? module.ec2_infrastructure[0].private_subnet_ids : []
  ) : var.subnet_ids
  
  security_group_ids = var.launch_type == "EC2" ? (
    length(module.ec2_infrastructure) > 0 ? [module.ec2_infrastructure[0].security_group_id] : []
  ) : var.security_group_ids
  
  security_group_rules = var.security_group_rules
  assign_public_ip     = var.launch_type == "EC2" ? false : var.assign_public_ip

  container_definitions = {
    dh-remote-executor = {
      cpu    = var.cpu
      memory = var.memory
      image  = format("%s:%s", var.datahub.image, var.datahub.image_tag)

      command = ["dockerize", "/start_datahub_executor.sh"]
      health_check = {
        command = ["CMD-SHELL", "/health_status /tmp/worker_liveness_heartbeat || exit 1"]
      }

      network_mode = var.network_mode

      port_mappings = []

      enable_cloudwatch_logging   = var.enable_cloudwatch_logging
      create_cloudwatch_log_group = var.create_cloudwatch_log_group
      log_configuration           = var.log_configuration
      readonly_root_filesystem    = false

      secrets = var.secrets

      environment = concat(var.environment, [
        {
          name  = "DATAHUB_GMS_URL"
          value = var.datahub.url
        },
        {
          name  = (local.version_legacy ? "DATAHUB_EXECUTOR_WORKER_ID" : "DATAHUB_EXECUTOR_POOL_ID")
          value = (local.version_legacy ? var.datahub.executor_id : var.datahub.executor_pool_id)
        },
        {
          name  = "DATAHUB_EXECUTOR_MODE"
          value = "worker"
        },
        {
          name  = "DATAHUB_EXECUTOR_INGESTION_MAX_WORKERS"
          value = var.datahub.executor_ingestions_workers
        },
        {
          name  = "DATAHUB_EXECUTOR_MONITORS_MAX_WORKERS"
          value = var.datahub.executor_monitors_workers
        },
        {
          name  = "DATAHUB_EXECUTOR_INGESTION_SIGNAL_POLL_INTERVAL"
          value = var.datahub.executor_ingestions_poll_interval
        },
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.name
        },
      ])
    }
  }

  tags = var.tags
}
