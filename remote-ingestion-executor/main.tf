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

  cpu               = var.cpu
  memory            = var.memory
  ephemeral_storage = var.ephemeral_storage
  desired_count     = var.desired_count
  launch_type       = "FARGATE"

  enable_execute_command   = var.enable_execute_command
  requires_compatibilities = var.requires_compatibilities

  subnet_ids           = var.subnet_ids
  security_group_ids   = var.security_group_ids
  security_group_rules = var.security_group_rules
  assign_public_ip     = var.assign_public_ip

  propagate_tags = upper(var.propagate_tags)

  container_definitions = {
    dh-remote-executor = {
      cpu    = var.cpu
      memory = var.memory
      image  = format("%s:%s", var.datahub.image, var.datahub.image_tag)

      command = ["/start_datahub_executor.sh"]
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
        # Emit both pool id env vars set to the same value. Modern images read
        # DATAHUB_EXECUTOR_POOL_ID; legacy images (<= v0.3.8) read DATAHUB_EXECUTOR_WORKER_ID.
        # Writing both keeps the module compatible across image versions (mirrors the Helm chart).
        {
          name  = "DATAHUB_EXECUTOR_POOL_ID"
          value = var.datahub.executor_pool_id
        },
        {
          name  = "DATAHUB_EXECUTOR_WORKER_ID"
          value = var.datahub.executor_pool_id
        },
        {
          name  = "DATAHUB_EXECUTOR_MODE"
          value = var.datahub.channel == "KAFKA" ? "kafka-worker" : "worker"
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
        # Observe/Assertion/Monitor feature flags + per-platform assertion query timeouts.
        {
          name  = "ONLINE_SMART_ASSERTIONS_ENABLED"
          value = var.datahub.executor_online_smart_assertions_enabled
        },
        {
          name  = "DATAHUB_USE_OBSERVE_MODELS"
          value = var.datahub.executor_use_observe_models
        },
        {
          name  = "DATAHUB_USE_INFERENCE_V2"
          value = var.datahub.executor_use_inference_v2
        },
        {
          name  = "DATAHUB_EXECUTOR_ENABLE_DELTA_BOUNDS"
          value = var.datahub.executor_enable_delta_bounds
        },
        {
          name  = "DATAHUB_EXECUTOR_ALLOW_CALL_STATEMENTS"
          value = var.datahub.executor_allow_call_statements
        },
        {
          name  = "DATAHUB_EXECUTOR_SNOWFLAKE_QUOTE_COLUMNS"
          value = var.datahub.executor_snowflake_quote_columns
        },
        {
          name  = "DATAHUB_EXECUTOR_SNOWFLAKE_TIMEOUT"
          value = var.datahub.executor_snowflake_timeout
        },
        {
          name  = "DATAHUB_EXECUTOR_BIGQUERY_TIMEOUT"
          value = var.datahub.executor_bigquery_timeout
        },
        {
          name  = "DATAHUB_EXECUTOR_REDSHIFT_TIMEOUT"
          value = var.datahub.executor_redshift_timeout
        },
        {
          name  = "DATAHUB_EXECUTOR_DATABRICKS_TIMEOUT"
          value = var.datahub.executor_databricks_timeout
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
