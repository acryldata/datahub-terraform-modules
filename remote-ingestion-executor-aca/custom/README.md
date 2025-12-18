# DataHub Remote Executor - Azure Container Apps (Minimal)

Minimal Terraform module to deploy the DataHub Remote Ingestion Executor on Azure Container Apps.

## Features

- Deploys Container App Environment with VNet integration (required)
- Deploys Container App with DataHub executor
- Optional Resource Group creation (or use existing)
- Username/password authentication for container registry
- Requires existing subnet (not created by this module)

## Requirements

- Terraform >= 1.3.0
- Azure Provider >= 3.75.0
- A VNet with a subnet delegated to `Microsoft.App/environments` (minimum /23 CIDR)

## Provider Configuration

When using this as a module, configure the Azure provider in your root module:

```hcl
provider "azurerm" {
  features {}
  subscription_id = "your-subscription-id"
}
```

The included `provider.tf` is for standalone testing only.

## Subnet Requirements

For **consumption-only** Container App Environments (no workload profiles), the subnet must be:
- At least /23 in size (512 IP addresses)
- **No delegation** (empty delegations)
- Empty (not used by other resources)
- In the same region as the Container App Environment

Example subnet configuration (no delegation needed):

```hcl
resource "azurerm_subnet" "aca" {
  name                 = "aca-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/23"]
  # No delegation block - this is correct for consumption-only ACA
}
```

Or via Azure CLI:

```bash
az network vnet subnet create \
  --resource-group <rg-name> \
  --vnet-name <vnet-name> \
  --name aca-subnet \
  --address-prefixes 10.0.0.0/23
```

> **Note**: For workload profile environments (dedicated compute), delegation to `Microsoft.App/environments` IS required. This module uses consumption-only, so no delegation is needed.

## Usage

### Scenario 1: Create new Resource Group

```hcl
module "datahub_executor" {
  source = "./custom"

  # Resource Group
  create_resource_group = true
  resource_group_name   = "datahub-executor-rg"
  location              = "eastus"

  # Networking
  infrastructure_subnet_id = azurerm_subnet.aca.id

  # Container Registry
  container_registry_url      = "myacr.azurecr.io"
  container_registry_username = "myacr"
  container_registry_password = var.acr_password
  image_repository            = "myacr.azurecr.io/datahub-executor"
  image_tag                   = "v0.3.15.3-acryl"

  # DataHub
  datahub_gms_url      = "https://company.acryl.io/gms"
  datahub_access_token = var.datahub_token
  executor_pool_id     = "azure-pool"

  # Optional
  tags = {
    Environment = "prod"
    Team        = "Data Platform"
  }
}
```

### Scenario 2: Use existing Resource Group

```hcl
module "datahub_executor" {
  source = "./custom"

  # Resource Group (existing)
  create_resource_group = false
  resource_group_name   = "existing-rg"
  location              = "eastus"

  # Networking
  infrastructure_subnet_id = "/subscriptions/xxx/resourceGroups/xxx/providers/Microsoft.Network/virtualNetworks/xxx/subnets/aca-subnet"

  # Container Registry
  container_registry_url      = "myacr.azurecr.io"
  container_registry_username = "myacr"
  container_registry_password = var.acr_password
  image_repository            = "myacr.azurecr.io/datahub-executor"

  # DataHub
  datahub_gms_url      = "https://company.acryl.io/gms"
  datahub_access_token = var.datahub_token
  executor_pool_id     = "azure-pool"
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| `create_resource_group` | Whether to create a new resource group | `bool` | No | `true` |
| `resource_group_name` | Name of the resource group | `string` | Yes | - |
| `location` | Azure region | `string` | Yes | - |
| `name_prefix` | Prefix for resource names | `string` | No | `"datahub-executor"` |
| `environment` | Environment name | `string` | No | `"dev"` |
| `tags` | Tags to apply | `map(string)` | No | `{}` |
| `infrastructure_subnet_id` | Subnet ID for ACA (must exist) | `string` | Yes | - |
| `container_registry_url` | Registry server URL | `string` | Yes | - |
| `container_registry_username` | Registry username | `string` | Yes | - |
| `container_registry_password` | Registry password | `string` | Yes | - |
| `image_repository` | Image repository path | `string` | Yes | - |
| `image_tag` | Image tag | `string` | No | `"v0.3.15.3-acryl"` |
| `datahub_gms_url` | DataHub GMS URL | `string` | Yes | - |
| `datahub_access_token` | DataHub access token | `string` | Yes | - |
| `executor_pool_id` | Executor pool ID | `string` | Yes | - |
| `cpu` | CPU cores | `number` | No | `2.0` |
| `memory` | Memory (e.g., "4Gi") | `string` | No | `"4Gi"` |

## Outputs

| Name | Description |
|------|-------------|
| `resource_group_name` | The name of the resource group |
| `container_app_environment_id` | The ID of the Container App Environment |
| `container_app_id` | The ID of the Container App |
| `container_app_name` | The name of the Container App |
