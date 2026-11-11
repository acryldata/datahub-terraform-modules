output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.frontend.arn
}

output "datahub_url" {
  value = var.route53_zone_id != "" && var.dns_name != "" ? "https://${var.dns_name}" : null
}
