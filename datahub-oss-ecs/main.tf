# Wires together the modules under ./modules — one module per concern.

module "networking" {
  source = "./modules/networking"

  name                         = local.name
  vpc_cidr                     = var.vpc_cidr
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  azs                              = local.azs
  single_nat_gateway    = var.single_nat_gateway
}

module "security" {
  source = "./modules/security"

  name                  = local.name
  vpc_id                = module.networking.vpc_id
  alb_ingress_cidrs    = var.alb_ingress_cidrs
  frontend_port         = var.frontend_port
  gms_port               = var.gms_port
}

module "ecr" {
  source = "./modules/ecr"

  name                  = local.name
  image_tag_mutability = var.ecr_image_mutability
}

module "secrets" {
  source = "./modules/secrets"

  name = local.name
}

module "iam" {
  source = "./modules/iam"

  name                              = local.name
  datahub_secrets = module.secrets.datahub_secret_arn
}

module "data_stores" {
  source = "./modules/data_stores"

  name       = local.name
  aws_region = var.aws_region
  account_id = data.aws_caller_identity.current.account_id

  private_subnet_ids = module.networking.private_subnet_ids
  rds_sg_id           = module.security.rds_sg_id
  msk_sg_id           = module.security.msk_sg_id
  opensearch_sg_id    = module.security.opensearch_sg_id

  db_engine_version         = var.db_engine_version
  db_instance_class         = var.db_instance_class
  db_allocated_storage      = var.db_allocated_storage
  db_name                    = var.db_name
  db_username                = var.db_username
  db_backup_retention_days = var.db_backup_retention_days

  msk_kafka_version           = var.msk_kafka_version
  msk_number_of_broker_nodes = var.msk_number_of_broker_nodes
  msk_instance_type           = var.msk_instance_type
  msk_ebs_volume_size         = var.msk_ebs_volume_size

  opensearch_engine_version   = var.opensearch_engine_version
  opensearch_instance_type    = var.opensearch_instance_type
  opensearch_instance_count   = var.opensearch_instance_count
  opensearch_ebs_volume_size = var.opensearch_ebs_volume_size

  gms_task_role_arn  = module.iam.gms_task_role_arn
  gms_task_role_name = module.iam.gms_task_role_name
}

module "service_discovery" {
  source = "./modules/service_discovery"

  name   = local.name
  vpc_id = module.networking.vpc_id
}

module "load_balancer" {
  source = "./modules/load_balancer"

  name                   = local.name
  enable_public_access  = var.enable_public_access
  vpc_id                 = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_sg_id               = module.security.alb_sg_id
  acm_certificate_arn    = var.acm_certificate_arn
  frontend_port           = var.frontend_port
  route53_zone_id         = var.route53_zone_id
  dns_name                = var.dns_name
}

module "ecs" {
  source = "./modules/ecs"

  name       = local.name
  aws_region = var.aws_region

  private_subnet_ids = module.networking.private_subnet_ids

  frontend_sg_id       = module.security.frontend_sg_id
  gms_sg_id             = module.security.gms_sg_id
  actions_sg_id         = module.security.actions_sg_id
  system_update_sg_id = module.security.system_update_sg_id

  execution_role_arn      = module.iam.execution_role_arn
  gms_task_role_arn       = module.iam.gms_task_role_arn
  frontend_task_role_arn = module.iam.frontend_task_role_arn
  actions_task_role_arn   = module.iam.actions_task_role_arn

  gms_image      = local.gms_image
  upgrade_image  = local.upgrade_image
  frontend_image = local.frontend_image
  actions_image  = local.actions_image

  frontend_port   = var.frontend_port
  frontend_cpu    = var.frontend_cpu
  frontend_memory = var.frontend_memory
  gms_port         = var.gms_port
  gms_cpu          = var.gms_cpu
  gms_memory       = var.gms_memory
  actions_cpu      = var.actions_cpu
  actions_memory   = var.actions_memory

  frontend_desired_count = var.frontend_desired_count
  gms_desired_count       = var.gms_desired_count
  actions_desired_count   = var.actions_desired_count

  db_username = var.db_username
  db_name      = var.db_name
  rds_address = module.data_stores.rds_address
  rds_port     = module.data_stores.rds_port

  msk_bootstrap_brokers_tls = module.data_stores.msk_bootstrap_brokers_tls
  opensearch_endpoint         = module.data_stores.opensearch_endpoint

  datahub_secret_arn = module.secrets.datahub_secret_arn

  metadata_service_auth_enabled = var.metadata_service_auth_enabled
  datahub_system_client_id       = var.datahub_system_client_id

  gms_cloudmap_dns           = module.service_discovery.gms_dns_name
  gms_service_registry_arn = module.service_discovery.gms_service_arn

  target_group_arn      = module.load_balancer.target_group_arn

}
