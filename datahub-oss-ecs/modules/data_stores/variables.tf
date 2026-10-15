variable "name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "rds_sg_id" {
  type = string
}

variable "msk_sg_id" {
  type = string
}

variable "opensearch_sg_id" {
  type = string
}

# --- RDS ---

variable "db_engine_version" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "db_allocated_storage" {
  type = number
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_backup_retention_days" {
  type = number
}

# --- MSK ---

variable "msk_kafka_version" {
  type = string
}

variable "msk_number_of_broker_nodes" {
  type = number
}

variable "msk_instance_type" {
  type = string
}

variable "msk_ebs_volume_size" {
  type = number
}

# --- OpenSearch ---

variable "opensearch_engine_version" {
  type = string
}

variable "opensearch_instance_type" {
  type = string
}

variable "opensearch_instance_count" {
  type = number
}

variable "opensearch_ebs_volume_size" {
  type = number
}

# --- Access ---

variable "gms_task_role_arn" {
  description = "Principal allowed to call the OpenSearch domain (used in its access policy)."
  type        = string
}

variable "gms_task_role_name" {
  description = "IAM role name to attach the OpenSearch access inline policy to."
  type        = string
}
