# DataHub Remote Ingestion Executor - Azure Container Apps

This Terraform module deploys a DataHub Remote Ingestion Executor on Azure Container Apps (ACA). The executor enables running ingestion and monitoring tasks in your Azure environment while connecting to DataHub Cloud.

## Overview

The Remote Executor is a containerized worker that:
- Polls DataHub Cloud for ingestion and monitoring tasks
- Executes tasks within your Azure environment
- Reports results back to DataHub Cloud
- Requires only **outbound** network connectivity (no inbound required)

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 Azure Container Apps                         │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              DataHub Executor Container               │   │
│  │                                                       │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │   │
│  │  │  Ingestion  │  │   Monitor   │  │    Task     │  │   │
│  │  │   Workers   │  │   Workers   │  │   Polling   │  │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                   │
└──────────────────────────┼───────────────────────────────────┘
                           │ Outbound HTTPS (443)
                           ▼
              ┌────────────────────────┐
              │   DataHub Cloud (GMS)  │
              │   AWS SQS Queues       │
              └────────────────────────┘
```

## Prerequisites

1. **Azure Resource Providers** - The following providers must be registered on your subscription (one-time operation):
   ```bash
   # Register required resource providers
   az provider register --namespace Microsoft.App --wait
   az provider register --namespace Microsoft.OperationalInsights --wait
   
   # Verify registration status
   az provider show -n Microsoft.App --query "registrationState"
   az provider show -n Microsoft.OperationalInsights --query "registrationState"
   ```

2. **Azure Subscription** with permissions to create:
   - Resource Groups
   - Container App Environments
   - Container Apps
   - User Assigned Managed Identities
   - Role Assignments

2. **DataHub Cloud** account with:
   - A Remote Executor Pool created in the DataHub UI
   - A Personal Access Token (PAT) for the executor

3. **Container Registry** containing the DataHub executor image:
   - Azure Container Registry (recommended)
   - Or any accessible container registry

4. **Network Connectivity** (outbound only):
   - DataHub GMS endpoint (HTTPS/443)
   - AWS SQS endpoints (HTTPS/443)
   - Container registry (HTTPS/443)

## Quick Start

### Basic Deployment

```hcl
module "datahub_executor" {
  source = "./remote-ingestion-executor-aca"

  # Azure Configuration
  resource_group_name = "my-datahub-rg"
  location            = "eastus"
  environment         = "prod"

  # DataHub Configuration
  datahub_gms_url      = "https://my-company.acryl.io/gms"
  datahub_access_token = var.datahub_access_token  # Use a variable, not hardcoded
  executor_pool_id     = "aca-executor-pool"

  # Container Image
  image_repository         = "myacr.azurecr.io/datahub-executor"
  image_tag                = "v0.3.15.3-acryl"
  container_registry_url   = "myacr.azurecr.io"
  enable_managed_identity_acr = true
  acr_name                 = "myacr"
}
```

### Deployment with Key Vault

```hcl
module "datahub_executor" {
  source = "./remote-ingestion-executor-aca"

  # Azure Configuration
  resource_group_name = "my-datahub-rg"
  location            = "eastus"
  environment         = "prod"

  # DataHub Configuration (using Key Vault)
  datahub_gms_url       = "https://my-company.acryl.io/gms"
  key_vault_id          = azurerm_key_vault.main.id
  key_vault_secret_name = "datahub-access-token"
  executor_pool_id      = "aca-executor-pool"

  # Container Image
  image_repository         = "myacr.azurecr.io/datahub-executor"
  image_tag                = "v0.3.15.3-acryl"
  container_registry_url   = "myacr.azurecr.io"
  enable_managed_identity_acr = true
  acr_name                 = "myacr"
}
```

## Locked-Down Environment Configuration

For environments with restricted network connectivity, this module supports:

### 1. VNet Integration

Deploy the Container App into a private VNet:

```hcl
module "datahub_executor" {
  source = "./remote-ingestion-executor-aca"

  # ... other configuration ...

  # VNet Integration
  enable_vnet_integration        = true
  infrastructure_subnet_id       = azurerm_subnet.aca.id
  internal_load_balancer_enabled = true  # No public IP
}
```

**Subnet Requirements:**
- Minimum size: /23 (512 addresses)
- Must be delegated to `Microsoft.App/environments`
- Must have `Microsoft.App/environments` service endpoint enabled

### 2. Proxy Configuration

For environments requiring outbound proxy:

```hcl
module "datahub_executor" {
  source = "./remote-ingestion-executor-aca"

  # ... other configuration ...

  # Proxy Settings
  http_proxy  = "http://proxy.company.com:8080"
  https_proxy = "http://proxy.company.com:8080"
  no_proxy    = "localhost,127.0.0.1,.internal.company.com"
}
```

### 3. Custom CA Certificates

For environments with custom/corporate CA certificates:

**Option A: Using Azure Files**

```hcl
module "datahub_executor" {
  source = "./remote-ingestion-executor-aca"

  # ... other configuration ...

  # Custom CA Certificates via Azure Files
  azure_files_account_name = "mystorageaccount"
  azure_files_share_name   = "ca-certs"
  azure_files_account_key  = var.storage_account_key
  custom_ca_cert_path      = "/mnt/ca-certs/ca-bundle.crt"
}
```

**Option B: Build into Custom Image**

Create a custom Docker image with certificates pre-installed:

```dockerfile
FROM 795586375822.dkr.ecr.us-west-2.amazonaws.com/datahub-executor:v0.3.15.3-acryl

COPY custom-ca.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
```

### 4. Required Outbound Connectivity

For locked-down environments, ensure these destinations are accessible:

| Destination | Port | Purpose |
|------------|------|---------|
| `*.acryl.io` | 443 | DataHub Cloud GMS API |
| `sqs.*.amazonaws.com` | 443 | AWS SQS (task queue) |
| Your container registry | 443 | Image pull |
| `*.vault.azure.net` | 443 | Key Vault (if used) |

### Network Security Group (NSG) Rules

Example NSG outbound rules for locked-down environment:

```hcl
resource "azurerm_network_security_rule" "allow_datahub" {
  name                        = "allow-datahub-outbound"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.aca.name
}
```

## Configuration Reference

### Required Variables

| Variable | Description |
|----------|-------------|
| `resource_group_name` | Azure resource group name |
| `location` | Azure region |
| `datahub_gms_url` | DataHub GMS endpoint URL |
| `datahub_access_token` OR `key_vault_id` | Authentication (one required) |
| `image_repository` | Container image repository |
| `container_registry_url` | Registry server URL |

### Worker Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `executor_pool_id` | `"aca-executor-pool"` | Pool ID (must match DataHub UI) |
| `ingestion_max_workers` | `4` | Concurrent ingestion workers |
| `monitors_max_workers` | `10` | Concurrent monitor workers |
| `ingestion_signal_poll_interval` | `2` | Poll interval (seconds) |

### Resource Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `cpu` | `4.0` | CPU cores (0.25 - 4.0) |
| `memory` | `"8Gi"` | Memory (0.5Gi - 8Gi) |

**Note:** Azure Container Apps has two compute models:
- **Consumption Plan** (default): Max 2 CPU / 4Gi per container
- **Workload Profiles** (dedicated): Max 4 CPU / 8Gi per container

To use 4 CPU / 8Gi, set `workload_profile_name` to a dedicated profile name. The module will automatically configure the environment with workload profiles.
| `min_replicas` | `1` | Minimum replicas (must be >= 1) |
| `max_replicas` | `3` | Maximum replicas |

### Environment Variables

The module automatically sets these environment variables:

| Environment Variable | Description |
|---------------------|-------------|
| `DATAHUB_GMS_URL` | DataHub GMS endpoint |
| `DATAHUB_GMS_TOKEN` | Access token (from secret) |
| `DATAHUB_EXECUTOR_MODE` | Always `"worker"` |
| `DATAHUB_EXECUTOR_POOL_ID` | Executor pool ID |
| `DATAHUB_EXECUTOR_INGESTION_MAX_WORKERS` | Max ingestion workers |
| `DATAHUB_EXECUTOR_MONITORS_MAX_WORKERS` | Max monitor workers |
| `HTTP_PROXY` / `HTTPS_PROXY` / `NO_PROXY` | Proxy settings (if configured) |
| `SSL_CERT_FILE` / `REQUESTS_CA_BUNDLE` | CA cert path (if configured) |

Add custom environment variables:

```hcl
module "datahub_executor" {
  # ... other configuration ...

  extra_env_vars = {
    "CUSTOM_VAR" = "value"
  }

  extra_secret_env_vars = {
    "SECRET_VAR" = var.secret_value
  }
}
```

## Comparison: AKS vs ACA

| Feature | AKS (Helm) | ACA (This Module) |
|---------|------------|-------------------|
| Deployment Method | Helm chart | Terraform only |
| Complexity | Higher (K8s cluster mgmt) | Lower (serverless) |
| Control | Full K8s API access | Limited configuration |
| Scaling | HPA, KEDA | Built-in autoscaling |
| Max Resources | Node-dependent | 4 CPU, 8GB per container |
| Init Containers | Supported | Not supported |
| Persistent Volumes | Full PVC support | Azure Files only |
| Cost | Cluster + nodes | Consumption-based |
| Official Support | Helm chart provided | Custom implementation |

## ACA Limitations

1. **No Init Containers**: CA certificate installation must be done via:
   - Custom image with certificates baked in
   - Azure Files volume mount

2. **Resource Limits**: Maximum 4 CPU cores and 8GB memory per container

3. **No Privileged Containers**: Cannot run privileged operations

4. **Secret Refresh**: Secrets require container restart to refresh (unlike K8s volume-mounted secrets)

5. **No Pod Disruption Budgets**: Scaling is managed by ACA

6. **Limited Probes**: Only HTTP/TCP probes supported (exec probes limited)

## Troubleshooting

### Check Container Status

```bash
# Show container app details (status, resources, revision)
az containerapp show \
  --name datahub-executor-prod \
  --resource-group my-datahub-rg \
  --query "{name:name, status:properties.runningStatus, cpu:properties.template.containers[0].resources.cpu, memory:properties.template.containers[0].resources.memory, revision:properties.latestRevisionName}" \
  -o table
```

### Viewing Logs

```bash
# Stream live logs (useful for debugging)
az containerapp logs show \
  --name datahub-executor-prod \
  --resource-group my-datahub-rg \
  --follow

# Show recent logs (last N lines)
az containerapp logs show \
  --name datahub-executor-prod \
  --resource-group my-datahub-rg \
  --tail 50

# Via Log Analytics (historical logs)
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'datahub-executor-prod' | order by TimeGenerated desc | take 100"
```

### Common Issues

**1. Container won't start**
- Check container registry credentials
- Verify managed identity has AcrPull role
- Check image tag exists in registry

**2. Cannot connect to DataHub**
- Verify `datahub_gms_url` is correct
- Check network connectivity (firewall/NSG rules)
- Verify access token is valid

**3. Tasks not being picked up**
- Confirm `executor_pool_id` matches the pool in DataHub UI
- Check executor pool is in `READY` status
- Verify SQS connectivity (AWS endpoints)

**4. Proxy issues**
- Ensure both `http_proxy` and `https_proxy` are set
- Add DataHub endpoints to `no_proxy` if needed
- Check proxy allows connections to AWS SQS

### Restart Container App

```bash
az containerapp revision restart \
  --name datahub-executor-prod \
  --resource-group my-datahub-rg \
  --revision <revision-name>
```

## Outputs

| Output | Description |
|--------|-------------|
| `container_app_id` | Container App resource ID |
| `container_app_name` | Container App name |
| `managed_identity_principal_id` | Identity principal ID |
| `managed_identity_client_id` | Identity client ID |
| `container_app_environment_id` | Environment ID |
| `deployment_summary` | Full deployment configuration summary |

## License

This module is provided as part of the DataHub Terraform Modules collection.
