resource "aws_service_discovery_private_dns_namespace" "this" {
  name        = "${var.name}.internal"
  description = "Private service discovery namespace for DataHub ECS services"
  vpc         = var.vpc_id
}

resource "aws_service_discovery_service" "gms" {
  name = "gms"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.this.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}
