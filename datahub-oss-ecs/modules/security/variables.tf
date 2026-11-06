variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB on port 443."
  type        = list(string)
}

variable "frontend_port" {
  type = number
}

variable "gms_port" {
  type = number
}
