variable "name" {
  type = string
}

variable "enable_public_access" {
  type = bool
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "frontend_port" {
  type = number
}

variable "route53_zone_id" {
  type    = string
  default = ""
}

variable "dns_name" {
  type    = string
  default = ""
}
