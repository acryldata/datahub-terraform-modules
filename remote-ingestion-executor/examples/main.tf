# Example usage of the DataHub Remote Ingestion Executor module
# This file shows how to deploy either Fargate or EC2 configurations
#
# Usage:
#   terraform apply -var-file=fargate.tfvars.example
#   terraform apply -var-file=ec2.tfvars.example

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
  region = "us-west-2"  # Change to your preferred region
}

# Variables that correspond to the .tfvars files
# These are minimal and just pass through to the main module
variable "cluster_name" { 
  type = string 
}

variable "datahub" { 
  type = any 
}

variable "service_name" { 
  type = string 
}

variable "desired_count" { 
  type = number 
}

variable "launch_type" { 
  type = string 
}

variable "cpu" { 
  type = number 
}

variable "memory" { 
  type = number 
}

variable "ec2_config" { 
  type    = any
  default = {} 
}

variable "subnet_ids" { 
  type    = list(string)
  default = [] 
}

variable "assign_public_ip" { 
  type    = bool
  default = false 
}

variable "security_group_rules" { 
  type    = any
  default = {} 
}

variable "create_tasks_iam_role" { 
  type    = bool
  default = true 
}

variable "create_task_exec_iam_role" { 
  type    = bool
  default = true 
}

variable "task_exec_secret_arns" { 
  type    = list(string)
  default = [] 
}

variable "secrets" { 
  type    = any
  default = [] 
}

variable "enable_cloudwatch_logging" { 
  type    = bool
  default = true 
}

variable "create_cloudwatch_log_group" { 
  type    = bool
  default = true 
}

variable "enable_execute_command" { 
  type    = bool
  default = true 
}

variable "environment" { 
  type    = any
  default = [] 
}

variable "tags" { 
  type    = map(string)
  default = {} 
}

# Deploy the DataHub Remote Ingestion Executor
module "datahub_remote_executor" {
  source = "../"

  # Pass through all variables from .tfvars files
  cluster_name = var.cluster_name
  datahub      = var.datahub
  
  service_name  = var.service_name
  desired_count = var.desired_count
  launch_type   = var.launch_type
  
  cpu    = var.cpu
  memory = var.memory
  
  ec2_config = var.ec2_config
  
  subnet_ids       = var.subnet_ids
  assign_public_ip = var.assign_public_ip
  
  security_group_rules = var.security_group_rules
  
  create_tasks_iam_role     = var.create_tasks_iam_role
  create_task_exec_iam_role = var.create_task_exec_iam_role
  
  task_exec_secret_arns = var.task_exec_secret_arns
  secrets               = var.secrets
  
  enable_cloudwatch_logging   = var.enable_cloudwatch_logging
  create_cloudwatch_log_group = var.create_cloudwatch_log_group
  enable_execute_command      = var.enable_execute_command
  
  environment = var.environment
  tags        = var.tags
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

# EC2-specific outputs (only populated when launch_type = "EC2")
output "private_subnet_ids" {
  description = "IDs of the private subnets used (EC2 only)"
  value       = module.datahub_remote_executor.private_subnet_ids
}

output "instance_id" {
  description = "ID of the EC2 instance (EC2 only)"
  value       = module.datahub_remote_executor.instance_id
}
