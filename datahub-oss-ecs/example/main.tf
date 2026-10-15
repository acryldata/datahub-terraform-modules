# Example: deploying DataHub on AWS ECS with this Terraform module.
#
# Run from this directory (examples/...), which calls the root module via
# `source = "../"`. Replace every <placeholder> before running `terraform apply`.
#
# All sizing values below match the example configuration in the deployment
# guide. They are a starting point, not a sizing recommendation.

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Pin to the provider version constraint declared by the root module.
    }
  }
}

locals {
  aws_region = "us-east-2"

  # Set to false for a private deployment (no public ALB). Frontend is then
  # reachable only through a VPN or other private connectivity into the VPC.
  enable_public_access = true

  # Used only when enable_public_access = true.
  dns_name            = "datahub.<your-domain>"
  route53_zone_id     = "<route53-hosted-zone-id>"
  acm_certificate_arn = "arn:aws:acm:us-east-2:<account-id>:certificate/<certificate-id>"
}

module "datahub_ecs" {
  source = "../"

  aws_region = local.aws_region

  # --- Networking -----------------------------------------------------------
  # Three private subnets across three AZs, so the 3-node MSK cluster can place
  # one broker per AZ.
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]

  # One shared NAT gateway keeps cost down. Use one per AZ for high availability.
  single_nat_gateway = true

  # --- Security -------------------------------------------------------------
  # CIDRs allowed to reach the ALB. Restrict this (for example to your office or
  # VPN range) rather than leaving it open to the internet.
  alb_ingress_cidrs = ["<your-allowed-cidr>/32"]

  frontend_port = 9002
  gms_port      = 8080

  # --- ECR ------------------------------------------------------------------
  # Immutable tags match the guide's recommendation to pin images to a release tag.
  ecr_image_mutability = "IMMUTABLE"

  # --- Amazon RDS (MySQL) ---------------------------------------------------
  db_engine_version        = "8.0"
  db_instance_class        = "db.t3.small"
  db_allocated_storage     = 20
  db_name                  = "datahub"
  db_username              = "datahub"
  db_backup_retention_days = 7

  # --- Amazon MSK -----------------------------------------------------------
  msk_kafka_version          = "3.6.0"
  msk_number_of_broker_nodes = 3
  msk_instance_type          = "kafka.t3.small"
  msk_ebs_volume_size        = 50

  # --- Amazon OpenSearch Service --------------------------------------------
  opensearch_engine_version  = "OpenSearch_2.11"
  opensearch_instance_type   = "t3.medium.search"
  opensearch_instance_count  = 3
  opensearch_ebs_volume_size = 50

  # --- Load balancer and DNS ------------------------------------------------
  enable_public_access = local.enable_public_access
  acm_certificate_arn  = local.acm_certificate_arn
  route53_zone_id      = local.route53_zone_id
  dns_name             = local.dns_name

  # --- ECS services ---------------------------------------------------------
  frontend_cpu    = 1024
  frontend_memory = 2048
  gms_cpu         = 1024
  gms_memory      = 2048
  actions_cpu     = 1024
  actions_memory  = 2048

  frontend_desired_count = 1
  gms_desired_count      = 1
  actions_desired_count  = 1

  # --- Metadata service authentication --------------------------------------
  # The matching DATAHUB_SYSTEM_CLIENT_SECRET is stored in AWS Secrets Manager
  # (created by the secrets module) and passed to the tasks as an ECS secret.
  metadata_service_auth_enabled = true
  datahub_system_client_id      = "__datahub_system"

  # --- Not shown here -------------------------------------------------------
  # The root module also takes the inputs that determine the resource name
  # prefix and the DataHub image versions (gms, upgrade, frontend, actions).
  # Copy those variables from the root variables.tf and pin the images to a
  # DataHub release tag, for example v0.14.1. On DataHub 1.5 and later, GMS also
  # needs DATAHUB_TOKEN_SERVICE_SIGNING_KEY and DATAHUB_TOKEN_SERVICE_SALT.
}
