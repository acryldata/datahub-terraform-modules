output "rds_endpoint" {
  description = "host:port"
  value       = aws_db_instance.this.endpoint
}

output "rds_address" {
  value = aws_db_instance.this.address
}

output "rds_port" {
  value = aws_db_instance.this.port
}

output "msk_bootstrap_brokers_tls" {
  value = aws_msk_cluster.this.bootstrap_brokers_tls
}

output "opensearch_endpoint" {
  value = aws_opensearch_domain.this.endpoint
}

output "opensearch_domain_arn" {
  value = aws_opensearch_domain.this.arn
}
