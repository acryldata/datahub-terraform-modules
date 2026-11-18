variable "name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

# --- Security groups ---

variable "frontend_sg_id" {
  type = string
}

variable "gms_sg_id" {
  type = string
}

variable "actions_sg_id" {
  type = string
}

variable "system_update_sg_id" {
  type = string
}

# --- IAM ---

variable "execution_role_arn" {
  type = string
}

variable "gms_task_role_arn" {
  type = string
}

variable "frontend_task_role_arn" {
  type = string
}

variable "actions_task_role_arn" {
  type = string
}

# --- Images ---

variable "gms_image" {
  type = string
}

variable "upgrade_image" {
  type = string
}

variable "frontend_image" {
  type = string
}

variable "actions_image" {
  type = string
}

# --- Sizing ---

variable "frontend_port" {
  type = number
}

variable "frontend_cpu" {
  type = number
}

variable "frontend_memory" {
  type = number
}

variable "gms_port" {
  type = number
}

variable "gms_cpu" {
  type = number
}

variable "gms_memory" {
  type = number
}

variable "actions_cpu" {
  type = number
}

variable "actions_memory" {
  type = number
}

variable "frontend_desired_count" {
  type = number
}

variable "gms_desired_count" {
  type = number
}

variable "actions_desired_count" {
  type = number
}

# --- Data store connectivity ---

variable "db_username" {
  type = string
}

variable "db_name" {
  type = string
}

variable "rds_address" {
  type = string
}

variable "rds_port" {
  type = number
}

variable "msk_bootstrap_brokers_tls" {
  type = string
}

variable "opensearch_endpoint" {
  type = string
}

# --- Secrets ---

variable "datahub_secret_arn" {
  type = string
}

# --- DataHub application config ---

variable "metadata_service_auth_enabled" {
  type = bool
}

variable "datahub_system_client_id" {
  type = string
}

# --- Service discovery ---

variable "gms_cloudmap_dns" {
  type = string
}

variable "gms_service_registry_arn" {
  type = string
}

# --- Load balancer ---

variable "target_group_arn" {
  description = "ALB target group Frontend registers with."
  type        = string
}
