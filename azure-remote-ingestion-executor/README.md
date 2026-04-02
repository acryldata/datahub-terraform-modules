# Azure Container Instance - DataHub Remote Ingestion Executor

Terraform module to deploy the DataHub Remote Ingestion Executor on Azure Container Instances (ACI).

## Usage

### Basic Example

```hcl
module "datahub_executor" {
  source = "git::git@github.com:acryldata/terraform-modules.git//azure-remote-ingestion-executor?ref=v0.1.0"

  name                = "dh-remote-executor"
  resource_group_name = "my-resource-group"
  location            = "eastus"

  datahub = {
    url              = "https://my-company.acryl.io/gms"
    executor_pool_id = "remote"
  }

  image_registry_credential = {
    server   = "docker.datahub.com"
    username = var.cloudsmith_username
    password = var.cloudsmith_api_token
  }

  secure_environment_variables = {
    DATAHUB_GMS_TOKEN = var.datahub_access_token
  }

  cpu    = 4
  memory = 8
}
```

### Private Networking Example

```hcl
module "datahub_executor" {
  source = "git::git@github.com:acryldata/terraform-modules.git//azure-remote-ingestion-executor?ref=v0.1.0"

  name                = "dh-remote-executor"
  resource_group_name = "my-resource-group"
  location            = "eastus"

  datahub = {
    url              = "https://my-company.acryl.io/gms"
    executor_pool_id = "remote"
  }

  ip_address_type = "Private"
  subnet_ids      = [azurerm_subnet.executor.id]

  identity_type = "SystemAssigned"

  image_registry_credential = {
    server   = "docker.datahub.com"
    username = var.cloudsmith_username
    password = var.cloudsmith_api_token
  }

  secure_environment_variables = {
    DATAHUB_GMS_TOKEN = var.datahub_access_token
  }

  cpu    = 4
  memory = 8
}
```

### Multiple Instances (Scaling)

Deploy multiple executor instances using Terraform's `count`:

```hcl
variable "executor_count" {
  type    = number
  default = 3
}

module "datahub_executor" {
  source = "git::git@github.com:acryldata/terraform-modules.git//azure-remote-ingestion-executor"
  
  count = var.executor_count
  name  = "dh-executor-${count.index + 1}"
  
  resource_group_name = "my-resource-group"
  location            = "eastus"

  datahub = {
    url = "https://my-company.acryl.io/gms"
  }

  image_registry_credential = {
    server   = "docker.datahub.com"
    username = var.cloudsmith_username
    password = var.cloudsmith_api_token
  }

  secure_environment_variables = {
    DATAHUB_GMS_TOKEN = var.datahub_token
  }

  cpu    = 4
  memory = 8
}
```

## Managing Secrets

The module supports multiple approaches for handling secrets:

### Environment Variables

```hcl
module "datahub_executor" {
  source = "git::git@github.com:acryldata/terraform-modules.git//azure-remote-ingestion-executor"
  
  name                = "dh-remote-executor"
  resource_group_name = "my-resource-group"
  location            = "eastus"

  datahub = {
    url = "https://my-company.acryl.io/gms"
  }

  # Add your own secrets as secure environment variables
  secure_environment_variables = {
    DATAHUB_GMS_TOKEN = var.datahub_token
    DATABASE_PASSWORD = var.db_password
    API_KEY           = var.api_key
    # Add any custom secrets your ingestion needs
  }

  image_registry_credential = {
    server   = "docker.datahub.com"
    username = var.cloudsmith_username
    password = var.cloudsmith_api_token
  }

  cpu    = 4
  memory = 8
}
```

### Secret Volumes

```hcl
module "datahub_executor" {
  source = "git::git@github.com:acryldata/terraform-modules.git//azure-remote-ingestion-executor"
  
  name                = "dh-remote-executor"
  resource_group_name = "my-resource-group"
  location            = "eastus"

  datahub = {
    url = "https://my-company.acryl.io/gms"
  }

  # Mount secrets as files in the container
  volumes = [
    {
      name       = "app-secrets"
      mount_path = "/mnt/secrets"
      read_only  = true
      secret = {
        # Creates files: /mnt/secrets/api-key, /mnt/secrets/config.json
        "api-key"     = base64encode(var.api_key)
        "config.json" = base64encode(jsonencode(var.config))
      }
    }
  ]

  secure_environment_variables = {
    DATAHUB_GMS_TOKEN = var.datahub_token
  }

  image_registry_credential = {
    server   = "docker.datahub.com"
    username = var.cloudsmith_username
    password = var.cloudsmith_api_token
  }

  cpu    = 4
  memory = 8
}
```

### Azure Key Vault

```hcl
# Use managed identity to access Key Vault secrets at runtime
module "datahub_executor" {
  source = "git::git@github.com:acryldata/terraform-modules.git//azure-remote-ingestion-executor"
  
  name                = "dh-remote-executor"
  resource_group_name = "my-resource-group"
  location            = "eastus"

  datahub = {
    url = "https://my-company.acryl.io/gms"
  }

  identity_type = "UserAssigned"
  identity_ids  = [azurerm_user_assigned_identity.executor.id]

  environment_variables = {
    AZURE_KEY_VAULT_URL = azurerm_key_vault.main.vault_uri
  }

  secure_environment_variables = {
    DATAHUB_GMS_TOKEN = var.datahub_token
  }

  cpu    = 4
  memory = 8
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.0 |
| azurerm | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| datahub | Acryl Executor configuration | `object` | n/a | yes |
| resource_group_name | Name of the Azure resource group | `string` | n/a | yes |
| location | Azure region where resources will be created | `string` | n/a | yes |
| name | Name of the container group and container | `string` | `"dh-remote-executor"` | no |
| cpu | Number of CPU cores for the container | `number` | `4` | no |
| memory | Amount of memory in GB for the container | `number` | `8` | no |
| restart_policy | Restart policy for the container group | `string` | `"Always"` | no |
| ip_address_type | The IP address type for the container group | `string` | `"Public"` | no |
| subnet_ids | List of subnet IDs (required for Private IP) | `list(string)` | `[]` | no |
| environment_variables | Environment variables to pass to the container | `map(string)` | `{}` | no |
| secure_environment_variables | Secure environment variables (sensitive) | `map(string)` | `{}` | no |
| image_registry_credential | Container image registry credentials | `object` | `null` | no |
| identity_type | The type of managed identity | `string` | `null` | no |
| identity_ids | List of user assigned identity IDs | `list(string)` | `[]` | no |
| log_analytics_workspace_id | The Log Analytics workspace ID | `string` | `null` | no |
| log_analytics_workspace_key | The Log Analytics workspace key | `string` | `null` | no |
| volumes | List of volumes to mount to the container | `list(object)` | `[]` | no |
| readiness_probe | Readiness probe configuration | `object` | See variables.tf | no |
| liveness_probe | Liveness probe configuration | `object` | See variables.tf | no |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

### DataHub Object Structure

```hcl
datahub = {
  image     = "docker.datahub.com/datahub-executor"  # Optional, default shown
  image_tag = "v0.3.16.1-acryl"                      # Optional, default shown
  url       = "https://my-company.acryl.io/gms"      # Required
  
  executor_pool_id                  = "remote"  # Optional, default: "remote"
  executor_ingestions_workers       = 4         # Optional, default: 4
  executor_monitors_workers         = 10        # Optional, default: 10
  executor_ingestions_poll_interval = 5         # Optional, default: 5
}
```

## Outputs

| Name | Description |
|------|-------------|
| container_group_id | The ID of the container group |
| container_group_name | The name of the container group |
| ip_address | The IP address allocated to the container group |
| fqdn | The FQDN of the container group |
| identity | The managed identity information |

## Notes

- Default container registry is `docker.datahub.com` (Cloudsmith) for cross-cloud compatibility
- Use `image_registry_credential` to authenticate with private registries
- For production deployments, use `ip_address_type = "Private"` with VNet integration
- Deploy multiple instances using Terraform's `count` parameter (see examples above)
- Resource units: CPU is in cores (1-4), Memory is in GB (1-16)

## License

This module is provided as part of the DataHub platform.
