variable "datahub" {
  description = "Acryl Executor configuration"
  type = object({
    # The container image
    image     = optional(string, "795586375822.dkr.ecr.us-west-2.amazonaws.com/datahub-executor")
    image_tag = optional(string, "v0.3.16.4-acryl")
    # Acryl DataHub URL: The URL for your DataHub instance, e.g. <your-company>.acryl.io/gms
    url = string

    # Unique Executor Pool Id. Warning - do not change this without consulting with your Acryl rep
    executor_pool_id = optional(string, "remote")

    # This variable is DEPRECATED. Use executor_pool_id instead.
    executor_id = optional(string, "remote")

    # Number of worker threads for ingestion jobs
    executor_ingestions_workers = optional(number, 4)
    # Number of worker threads for monitor jobs
    executor_monitors_workers = optional(number, 10)
    # Ingestion signal poll interval in seconds
    executor_ingestions_poll_interval = optional(number, 5)
  })
}

variable "cluster_name" {
  description = "Name of the cluster (up to 255 letters, numbers, hyphens, and underscores)"
  type        = string
  default     = ""
}

variable "cluster_configuration" {
  description = "The execute command configuration for the cluster"
  type        = any
  default     = {}
}

variable "create_tasks_iam_role" {
  description = "Determines whether the ECS tasks IAM role should be created"
  type        = bool
  default     = true
}

variable "tasks_iam_role_arn" {
  description = "Existing IAM role ARN"
  type        = string
  default     = null
}

variable "tasks_iam_role_name" {
  description = "Name to use on IAM role created"
  type        = string
  default     = null
}

variable "tasks_iam_role_policies" {
  description = "Map of IAM role policy ARNs to attach to the IAM role"
  type        = map(string)
  default     = {}
}

variable "create_task_exec_iam_role" {
  description = "Determines whether the ECS task definition IAM role should be created"
  type        = bool
  default     = false
}

variable "task_exec_iam_role_name" {
  description = "Name to use on IAM role created"
  type        = string
  default     = null
}

variable "create_task_exec_policy" {
  description = "Determines whether the ECS task definition IAM policy should be created. This includes permissions included in AmazonECSTaskExecutionRolePolicy as well as access to secrets and SSM parameters"
  type        = bool
  default     = true
}

variable "task_exec_iam_role_policies" {
  description = "Map of IAM role policy ARNs to attach to the IAM role"
  type        = map(string)
  default     = {}
}

variable "task_exec_ssm_param_arns" {
  description = "List of SSM parameter ARNs the task execution role will be permitted to get/read"
  type        = list(string)
  default     = []
}

variable "task_exec_secret_arns" {
  description = "List of SecretsManager secret ARNs the task execution role will be permitted to get/read"
  type        = list(string)
  default     = []
}

variable "service_name" {
  description = "Name of the service (up to 255 letters, numbers, hyphens, and underscores)"
  type        = string
  default     = "dh-remote-executor"
}

variable "cpu" {
  description = "Number of cpu units used by the task"
  type        = number
  default     = 1024
}

variable "memory" {
  description = "Amount (in MiB) of memory used by the task"
  type        = number
  default     = 2048
}

variable "network_mode" {
  description = "Docker networking mode to use for the containers in the task"
  type        = string
  default     = "awsvpc"
}

variable "security_group_ids" {
  description = "List of security groups to associate with the task"
  type        = list(string)
  default     = []
}

variable "security_group_rules" {
  description = "Security group rules to add to the security group created"
  type        = any
  default     = {}
}

variable "subnet_ids" {
  description = "List of subnets to associate with the task"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign a public IP address to the ENI"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logging" {
  description = "Determines whether CloudWatch logging is configured for the container definition"
  type        = bool
  default     = true
}

variable "create_cloudwatch_log_group" {
  description = "Determines whether a log group is created by this module. If not, AWS will automatically create one if logging is enabled"
  type        = bool
  default     = true
}

variable "log_configuration" {
  description = "The log configuration for the container"
  type        = any
  default     = {}
}

variable "secrets" {
  description = "The secrets to pass to the container. For more information, see [Specifying Sensitive Data](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/specifying-sensitive-data.html) in the Amazon Elastic Container Service Developer Guide"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "env_vars" {
  description = "The environment variables to pass to the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "desired_count" {
  description = "Number of instances of the task definition to place and keep running"
  type        = number
  default     = 1
}

variable "enable_execute_command" {
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Determines whether to enable autoscaling for the service"
  type        = bool
  default     = false
}

variable "launch_type" {
  description = "Launch type for the ECS service (EC2 or FARGATE)"
  type        = string
  default     = "FARGATE"
  
  validation {
    condition     = contains(["EC2", "FARGATE"], var.launch_type)
    error_message = "Launch type must be either 'EC2' or 'FARGATE'."
  }
}

# EC2-specific configuration
variable "ec2_config" {
  description = "Configuration for EC2 launch type"
  type = object({
    private_subnet_ids = optional(list(string), [])
    instance_type      = optional(string, "t3.large")
  })
  default = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
