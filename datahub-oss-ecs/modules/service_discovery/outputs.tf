output "gms_service_arn" {
  value = aws_service_discovery_service.gms.arn
}

output "gms_dns_name" {
  description = "DNS name Frontend/Actions use to reach GMS (DATAHUB_GMS_HOST)."
  value       = "${aws_service_discovery_service.gms.name}.${aws_service_discovery_private_dns_namespace.this.name}"
}
