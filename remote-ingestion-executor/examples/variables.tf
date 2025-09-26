# Variables for the example deployment
# These variables correspond to the values in fargate.tfvars or ec2.tfvars

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "datahub" {
  description = "DataHub configuration"
  type = object({
    url                              = string
    executor_pool_id                 = string
    executor_ingestions_workers      = number
    executor_monitors_workers        = number
    executor_ingestions_poll_interval = number
  })
}

variable "service_name" {
  description = "Name of the ECS service"
  type        = string
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
}

variable "launch_type" {
  description = "Launch type (FARGATE or EC2)"
  type        = string
}

variable "cpu" {
  description = "CPU units for the task"
  type        = number
}

variable "memory" {
  description = "Memory for the task"
  type        = number
}

variable "ec2_config" {
  description = "EC2-specific configuration"
  type = object({
    private_subnet_ids = optional(list(string), [])
    instance_type      = optional(string, "t3.large")
  })
  default = {}
}

variable "subnet_ids" {
  description = "Subnet IDs for Fargate deployment"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign public IP to tasks"
  type        = bool
  default     = false
}

variable "security_group_rules" {
  description = "Security group rules"
  type        = any
  default     = {}
}

variable "create_tasks_iam_role" {
  description = "Create tasks IAM role"
  type        = bool
  default     = true
}

variable "create_task_exec_iam_role" {
  description = "Create task execution IAM role"
  type        = bool
  default     = true
}

variable "task_exec_secret_arns" {
  description = "ARNs of secrets for task execution role"
  type        = list(string)
  default     = []
}

variable "secrets" {
  description = "Secrets to pass to the container"
  type        = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "enable_cloudwatch_logging" {
  description = "Enable CloudWatch logging"
  type        = bool
  default     = true
}

variable "create_cloudwatch_log_group" {
  description = "Create CloudWatch log group"
  type        = bool
  default     = true
}

variable "enable_execute_command" {
  description = "Enable ECS Exec"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment variables"
  type        = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
