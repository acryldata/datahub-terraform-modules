locals {
  version_components = regex("^v(\\d+)\\.(\\d+)\\.(\\d+)", var.datahub.image_tag)
  version_legacy     = (tonumber(local.version_components[0]) == 0 && tonumber(local.version_components[1]) <= 3 && tonumber(local.version_components[2]) <= 8) ? true : false
}
