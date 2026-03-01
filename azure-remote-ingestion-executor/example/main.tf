locals {
  datahub = {
    # Optional: Override default image (defaults to docker.datahub.com/re/datahub-executor:v0.3.16.2-acryl)
    # image     = "docker.datahub.com/re/datahub-executor"
    # image_tag = "v0.3.16.2-acryl"
    url = "https://<your-company>.acryl.io/gms"
  }
}

module "example" {
  source = "../"

  name                = "dh-remote-executor"
  resource_group_name = "rg-datahub-executor"
  location            = "eastus"

  datahub = local.datahub

  image_registry_credential = {
    server   = "docker.datahub.com"
    username = "XXX"
    password = "XXX"
  }

  secure_environment_variables = {
    DATAHUB_GMS_TOKEN = "XXX"
  }

  subnet_ids = ["subnet-XXX"]

  ip_address_type = "Private"

  cpu    = 4
  memory = 8

  tags = {
    Environment = "example"
  }
}
