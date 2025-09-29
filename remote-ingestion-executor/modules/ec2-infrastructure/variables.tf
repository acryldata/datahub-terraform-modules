variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of existing private subnet IDs to use for EC2 instances"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for ECS instance"
  type        = string
  default     = "t3.large"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
