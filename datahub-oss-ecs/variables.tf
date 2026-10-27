# -----------------------------------------------------------------------------
# General
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix resource names and tags."
  type        = string
  default     = "datahub"
}

variable "environment" {
  description = "Environment name (dev/staging/prod)."
  type    = string
  default = null
}

variable "tags" {
  description = "Additional tags applied to every resource, merged with the standard tags."
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
# This reference deployment provisions its own VPC with 3 public subnets (ALB only) and 3 private
# subnets (ECS tasks, RDS, MSK, OpenSearch) across 3 Availability Zones, plus a NAT gateway so
# private-subnet tasks can reach Secrets Manager, ECR, and Docker Hub. 

variable "vpc_cidr" {
  description = "CIDR block for the VPC created by this deployment."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets (ALB only). One per Availability Zone."
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets (ECS tasks, RDS, MSK, OpenSearch). One per Availability Zone."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "az_count" {
  description = <<-EOT
    Number of Availability Zones to spread subnets across. Defaults to 3 to match this deployment's
    default MSK broker count and OpenSearch node count. If you change msk_number_of_broker_nodes, keep
    az_count a divisor of it.
  EOT
  type    = number
  default = 3
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT gateway instead of one per AZ."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# RDS for MySQL
# -----------------------------------------------------------------------------

variable "db_engine_version" {
  description = "MySQL engine version. Confirm current supported versions with `aws rds describe-db-engine-versions --engine mysql`."
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.small"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage, in GB."
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Database name created on the RDS instance."
  type        = string
  default     = "datahub"
}

variable "db_username" {
  description = "Dedicated DataHub database user."
  type        = string
  default     = "datahub"
}

variable "db_backup_retention_days" {
  description = "RDS automated backup retention, in days. Reference deployment default only — increase for real backup/DR needs."
  type        = number
  default     = 7
}

# -----------------------------------------------------------------------------
# Amazon MSK
# -----------------------------------------------------------------------------

variable "msk_kafka_version" {
  description = "Kafka version for the MSK cluster. Confirm current supported versions with `aws kafka list-kafka-versions`."
  type        = string
  default     = "3.6.0"
}

variable "msk_number_of_broker_nodes" {
  description = "Number of MSK broker nodes. Must be a multiple of the number of subnets supplied (see az_count)."
  type        = number
  default     = 3
}

variable "msk_instance_type" {
  description = "MSK broker instance type."
  type        = string
  default     = "kafka.t3.small"
}

variable "msk_ebs_volume_size" {
  description = "EBS volume size per MSK broker, in GB."
  type        = number
  default     = 50
}

# -----------------------------------------------------------------------------
# Amazon OpenSearch Service
# -----------------------------------------------------------------------------

variable "opensearch_engine_version" {
  description = "OpenSearch engine version."
  type        = string
  default     = "OpenSearch_2.11"
}

variable "opensearch_instance_type" {
  description = "OpenSearch data node instance type."
  type        = string
  default     = "t3.medium.search"
}

variable "opensearch_instance_count" {
  description = "Number of OpenSearch data nodes. Must be a multiple of az_count for zone awareness."
  type        = number
  default     = 3
}

variable "opensearch_ebs_volume_size" {
  description = "EBS volume size per OpenSearch node, in GB (gp3)."
  type        = number
  default     = 50
}

# -----------------------------------------------------------------------------
# ECS / Fargate — images
# -----------------------------------------------------------------------------
# GMS and datahub-upgrade use the default DataHub images from Docker Hub. Frontend and Actions are
# customized, so they are pulled from the ECR repositories the ecr module creates — build and push those images before running
# `terraform apply` for the ECS services, or the tasks will fail to start.

variable "datahub_version" {
  description = "DataHub release tag to deploy (e.g. \"v0.14.1\"). Never use \"latest\" or \"debug\"."
  type        = string
  default     = "v0.14.1"

  validation {
    condition     = !contains(["latest", "debug"], var.datahub_version)
    error_message = "datahub_version must not be \"latest\" or \"debug\" — pin to a specific release tag."
  }
}

variable "gms_image" {
  description = "Full image reference for the GMS container. Defaults to the public DataHub image pinned to datahub_version."
  type        = string
  default     = null
}

variable "upgrade_image" {
  description = "Full image reference for the datahub-upgrade (System Update) container. Defaults to the public DataHub image pinned to datahub_version."
  type        = string
  default     = null
}

variable "frontend_image_tag" {
  description = "Tag to deploy from the custom Frontend ECR repository this deployment creates."
  type        = string
  default     = "v0.14.1"

  validation {
    condition     = !contains(["latest", "debug"], var.frontend_image_tag)
    error_message = "frontend_image_tag must not be \"latest\" or \"debug\"."
  }
}

variable "actions_image_tag" {
  description = "Tag to deploy from the custom Actions ECR repository this deployment creates."
  type        = string
  default     = "v0.14.1"

  validation {
    condition     = !contains(["latest", "debug"], var.actions_image_tag)
    error_message = "actions_image_tag must not be \"latest\" or \"debug\"."
  }
}

variable "ecr_image_mutability" {
  description = "ECR image tag mutability."
  type        = string
  default     = "IMMUTABLE"
}

# -----------------------------------------------------------------------------
# ECS / Fargate — service sizing
# -----------------------------------------------------------------------------

variable "frontend_port" {
  description = "Port the Frontend container listens on."
  type        = number
  default     = 9002
}

variable "frontend_cpu" {
  description = "Frontend task CPU units (Fargate)."
  type        = number
  default     = 1024
}

variable "frontend_memory" {
  description = "Frontend task memory, in MiB (Fargate)."
  type        = number
  default     = 2048
}

variable "gms_port" {
  description = "Port the GMS container listens on."
  type        = number
  default     = 8080
}

variable "gms_cpu" {
  description = "GMS task CPU units (Fargate)."
  type        = number
  default     = 1024
}

variable "gms_memory" {
  description = "GMS task memory, in MiB (Fargate)."
  type        = number
  default     = 2048
}

variable "actions_cpu" {
  description = "Actions task CPU units (Fargate)."
  type        = number
  default     = 1024
}

variable "actions_memory" {
  description = "Actions task memory, in MiB (Fargate)."
  type        = number
  default     = 2048
}

variable "frontend_desired_count" {
  description = "Desired number of Frontend tasks."
  type        = number
  default     = 1
}

variable "gms_desired_count" {
  description = "Desired number of GMS tasks."
  type        = number
  default     = 1
}

variable "actions_desired_count" {
  description = "Desired number of Actions tasks."
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# DataHub application configuration
# -----------------------------------------------------------------------------

variable "metadata_service_auth_enabled" {
  description = "Whether to enable authentication between DataHub services (METADATA_SERVICE_AUTH_ENABLED)."
  type        = bool
  default     = true
}

variable "datahub_system_client_id" {
  description = "DATAHUB_SYSTEM_CLIENT_ID value. Stored in Secrets Manager and injected into services that need it."
  type        = string
  default     = "__datahub_system"
}

# -----------------------------------------------------------------------------
# Public access (ALB + Route 53)
# -----------------------------------------------------------------------------

variable "enable_public_access" {
  description = "Whether to create a public-facing or private ALB."
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for the ALB's HTTPS listener. Required when enable_public_access is true."
  type        = string
  default     = ""
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB on port 443. Defaults to open internet — restrict to your VPN/corporate CIDR if DataHub should not be reachable from anywhere."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "route53_zone_id" {
  description = "Route 53 hosted zone ID to create the DataHub DNS record in. Leave empty to skip DNS record creation."
  type        = string
  default     = ""
}

variable "dns_name" {
  description = "Fully qualified DNS name for DataHub (e.g. datahub.example.com). Required if route53_zone_id is set."
  type        = string
  default     = ""
}
