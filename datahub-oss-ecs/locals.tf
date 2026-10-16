locals {
  environment = var.environment
  name        = "${var.project_name}-${local.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = local.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Default public images, pinned to var.datahub_version. Overridable via var.gms_image / var.upgrade_image.
  gms_image     = coalesce(var.gms_image, "acryldata/datahub-gms:${var.datahub_version}")
  upgrade_image = coalesce(var.upgrade_image, "acryldata/datahub-upgrade:${var.datahub_version}")

  # Custom images built per "Build custom DataHub images" in docs/deploy/aws-ecs.md, pushed to the
  # ECR repositories the ecr module creates.
  frontend_image = "${module.ecr.frontend_repository_url}:${var.frontend_image_tag}"
  actions_image  = "${module.ecr.actions_repository_url}:${var.actions_image_tag}"
}
