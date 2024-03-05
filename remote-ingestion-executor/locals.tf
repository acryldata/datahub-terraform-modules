locals {
  queue_region = coalesce(var.datahub.queue_region, data.aws_region.current.name)
}
