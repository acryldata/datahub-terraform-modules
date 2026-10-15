variable "name" {
  description = "Resource name prefix."
  type        = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (ALB only). One per AZ in var.azs."
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (ECS tasks, RDS, MSK, OpenSearch). One per AZ in var.azs."
  type        = list(string)
}

variable "azs" {
  description = "Availability Zones to spread subnets across."
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT gateway instead of one per AZ."
  type        = bool
  default     = true
}
