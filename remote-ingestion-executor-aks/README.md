# DataHub Remote Executor on Azure AKS

This Terraform module deploys DataHub Remote Executor to Azure Kubernetes Service (AKS) with comprehensive support for locked-down, highly restricted network environments.

## Table of Contents

- [Architecture](#architecture)
- [Requirements](#requirements)
- [Network Connectivity Options](#network-connectivity-options)
- [Container Registry Configuration](#container-registry-configuration)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Azure AD Workload Identity](#azure-ad-workload-identity)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

## Architecture

### Remote Executor Overview

The Remote Executor is a containerized worker that runs in your Azure environment and processes DataHub ingestion tasks. It uses a secure, queue-based architecture:

1. **Task Distribution**: DataHub dispatches ingestion tasks to AWS SQS queues
2. **Credential Management**: Executor authenticates to DataHub GMS using a token; GMS provides temporary AWS STS credentials (~1 hour validity, auto-refreshed every 45 minutes)
3. **Task Execution**: Executor polls SQS using temporary credentials, fetches tasks, and executes ingestion
4. **Secret Resolution**: Recipes reference secrets by URN (e.g., `urn:li:dataHubSecret:snowflake-password`); executor resolves actual values from GMS at execution time
5. **Progress Reporting**: Executor reports status and results back to DataHub GMS

### Security Model

- **No long-lived AWS credentials** stored on executor
- **Secrets never transit through SQS** (only secret references)
- **All communication is outbound** (no inbound ports required)
- **Temporary STS credentials expire automatically**
- **DataHub GMS token required** for authentication

### Communication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                      AKS Executor Pod                        │
│                                                              │
│  1. Authenticate with DataHub GMS (HTTPS/443)               │
│     └─ Provide DataHub access token                         │
│     └─ GMS calls AWS STS to generate temporary credentials  │
│                                                              │
│  2. Receive temporary AWS STS credentials from GMS          │
│     └─ Valid for ~1 hour, refreshed every 45 minutes        │
│     └─ Refresh by calling GMS again (not STS directly)      │
│                                                              │
│  3. Poll AWS SQS queue for tasks (HTTPS/443)                │
│     └─ Use temporary STS credentials from step 2            │
│                                                              │
│  4. Resolve secrets from DataHub GMS (HTTPS/443)            │
│     └─ Fetch actual secret values by URN reference          │
│                                                              │
│  5. Execute ingestion task                                  │
│     └─ Connect to data sources, extract metadata            │
│                                                              │
│  6. Report progress and results to DataHub GMS (HTTPS/443)  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Requirements

### Prerequisites

- **Azure subscription** with AKS cluster (Kubernetes 1.24+)
- **Terraform** >= 1.0
- **Azure CLI** authenticated (`az login`)
- **kubectl** configured for AKS cluster access
- **DataHub access token** (generated from DataHub UI → Settings → Access Tokens)
- **Executor pool created in DataHub UI** (Settings → Executor Pools)

### Required Outbound Connectivity

The executor requires **outbound HTTPS (443)** access to the following endpoints:

| Endpoint | Purpose | Example |
|----------|---------|---------|
| **DataHub GMS** | Fetch STS credentials, resolve secrets, report progress | `https://your-company.acryl.io/gms` |
| **AWS SQS** | Poll task queue | `https://sqs.us-west-2.amazonaws.com` |
| **Azure Container Registry** | Pull executor container image | `https://customername.azurecr.io` |

**Note:** The executor does NOT need direct access to AWS STS. GMS handles all STS credential operations (`sts:AssumeRole`) on behalf of the executor and returns temporary credentials via the `listExecutorConfigs` endpoint.

## Network Connectivity Options

For locked-down environments with restricted internet access, choose one of the following connectivity strategies:

### Option A: VPN or Azure ExpressRoute to AWS

Establish private network connectivity between your Azure VNet and AWS VPC.

**Architecture:**
```
AKS → Azure VNet → VPN/ExpressRoute → AWS VPC → SQS
```

**Requirements:**
- Azure ExpressRoute circuit or VPN Gateway
- AWS VPC with routing to SQS (and optionally STS if GMS also uses this path)
- BGP configuration for route propagation
- Route tables updated in both clouds

**Configuration:**
```hcl
# terraform.tfvars
http_proxy  = ""  # Not needed with direct connectivity
https_proxy = ""
```

**Pros:**
- Most secure option
- No internet exposure
- Predictable latency and bandwidth

**Cons:**
- Complex setup requiring cross-cloud networking expertise
- Additional cost for ExpressRoute/VPN
- Requires coordination between Azure and AWS network teams

### Option B: AWS PrivateLink for SQS Access

Use AWS PrivateLink to create private VPC endpoints for SQS service, accessible via VPN/ExpressRoute.

**Architecture:**
```
AKS → Azure VNet → VPN/ExpressRoute → AWS VPC → PrivateLink Endpoints → SQS
```

**Requirements:**
- AWS VPC with VPC endpoint for SQS (STS endpoint optional - only needed if GMS uses same path)
- Azure-to-AWS private connectivity (VPN/ExpressRoute)
- VPC endpoint DNS configuration

**Setup:**
1. Create VPC endpoint for SQS in AWS:
   ```bash
   # SQS VPC Endpoint (required for executor)
   aws ec2 create-vpc-endpoint \
     --vpc-id vpc-xxxxx \
     --service-name com.amazonaws.us-west-2.sqs \
     --route-table-ids rtb-xxxxx
   
   # STS VPC Endpoint (optional - only if GMS needs private access to STS)
   # aws ec2 create-vpc-endpoint \
   #   --vpc-id vpc-xxxxx \
   #   --service-name com.amazonaws.us-west-2.sts \
   #   --route-table-ids rtb-xxxxx
   ```

2. Configure DNS resolution for private endpoints

**Pros:**
- Private connectivity without internet traversal
- Works with existing VPN/ExpressRoute
- Better security than internet-based access

**Cons:**
- Still requires Azure-to-AWS network connectivity
- Additional AWS infrastructure costs
- DNS configuration complexity

### Option C: HTTPS Proxy or API Gateway

Deploy a forward proxy in your Azure VNet with limited egress, allowing controlled outbound access.

**Architecture:**
```
AKS → HTTP/HTTPS Proxy → Internet → AWS SQS & DataHub GMS
```

**Requirements:**
- Forward proxy deployed in Azure (Squid, nginx, Azure App Gateway)
- NSG rules allowing proxy egress to specific domains
- Proxy configured with allowlist of required endpoints

**Allowlist for Proxy:**
```
# Required domains
*.amazonaws.com          # AWS SQS (regional endpoint like sqs.us-west-2.amazonaws.com)
your-company.acryl.io   # DataHub GMS (or your custom domain)

# Note: AWS STS access is NOT required - GMS handles STS calls
```

**Configuration:**
```hcl
# terraform.tfvars
http_proxy  = "http://proxy.company.internal:8080"
https_proxy = "http://proxy.company.internal:8080"
no_proxy    = "localhost,127.0.0.1,.svc,.cluster.local"
```

**Example NSG Rules (for proxy server):**
```hcl
# Allow proxy to reach AWS SQS and DataHub GMS
resource "azurerm_network_security_rule" "proxy_aws" {
  name                        = "AllowProxyToAWS"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "10.0.1.0/24"  # Proxy subnet
  destination_address_prefix  = "Internet"
}
```

**Pros:**
- Simpler than VPN/ExpressRoute setup
- Centralized egress control and logging
- Works without cross-cloud networking
- Can implement additional security policies (URL filtering, SSL inspection)

**Cons:**
- Proxy becomes single point of failure (deploy HA proxy)
- Requires proxy infrastructure maintenance
- Potential performance bottleneck
- Additional latency compared to direct connectivity

## Container Registry Configuration

### Azure Container Registry (ACR) with Private Endpoint

**Recommended for locked-down environments:** Mirror the DataHub executor image to your own ACR, accessible via private endpoint (no internet required).

#### Step 1: Copy Image to Your ACR

```bash
# Login to source registry (DataHub provided)
docker login docker.datahub.com -u <username> -p <password>

# Pull DataHub executor image
docker pull docker.datahub.com/enterprise/datahub-executor:v0.3.13-acryl

# Tag for your ACR
docker tag docker.datahub.com/enterprise/datahub-executor:v0.3.13-acryl \
  customername.azurecr.io/datahub-executor:v0.3.13-acryl

# Login to your ACR
az acr login --name customername

# Push to your ACR
docker push customername.azurecr.io/datahub-executor:v0.3.13-acryl
```

#### Step 2: Configure ACR Private Endpoint

```bash
# Create private endpoint for ACR
az network private-endpoint create \
  --name acr-private-endpoint \
  --resource-group <resource-group> \
  --vnet-name <vnet-name> \
  --subnet <subnet-name> \
  --private-connection-resource-id $(az acr show --name customername --query id -o tsv) \
  --group-id registry \
  --connection-name acr-connection
```

#### Step 3: Configure Terraform Variables

**Option 1: Using Azure AD Workload Identity (Recommended)**
```hcl
# terraform.tfvars
container_registry_url      = "customername.azurecr.io"
image_repository            = "customername.azurecr.io/datahub-executor"
enable_workload_identity    = true
acr_name                    = "customername"
acr_resource_group_name     = "my-acr-rg"
```

**Option 2: Using Image Pull Secrets**
```hcl
# terraform.tfvars
container_registry_url      = "customername.azurecr.io"
container_registry_username = "customername"
container_registry_password = "<acr-password-or-token>"
image_repository            = "customername.azurecr.io/datahub-executor"
enable_workload_identity    = false
```

## Quick Start

### 1. Clone and Configure

```bash
cd remote-ingestion-executor-aks
cp terraform.tfvars.example terraform.tfvars
```

### 2. Edit Configuration

Edit `terraform.tfvars` with your values:

```hcl
# Azure Configuration
subscription_id     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
resource_group_name = "my-aks-rg"
aks_cluster_name    = "my-aks-cluster"

# DataHub Configuration
datahub_gms_url           = "https://your-company.acryl.io/gms"
datahub_access_token      = "your-datahub-access-token"
datahub_remote_executor_pool_id = "aks-executor-pool"

# Container Registry (Azure ACR)
container_registry_url      = "customername.azurecr.io"
image_repository            = "customername.azurecr.io/datahub-executor"
image_tag                   = "v0.3.13-acryl"

# Enable Workload Identity for ACR access (recommended)
enable_workload_identity = true
acr_name                 = "customername"
acr_resource_group_name  = "my-acr-rg"

# For locked-down environments with proxy
http_proxy  = "http://proxy.internal:8080"
https_proxy = "http://proxy.internal:8080"
no_proxy    = "localhost,127.0.0.1,.svc,.cluster.local"
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Verify Deployment

```bash
# Configure kubectl
az aks get-credentials --name my-aks-cluster --resource-group my-aks-rg

# Check pods
kubectl get pods -n datahub-remote-executor

# View logs
kubectl logs -n datahub-remote-executor -l app.kubernetes.io/name=datahub-executor-worker --tail=50
```

**Expected log output:**
```
Successfully fetched executor configs for executorIds: ['aks-executor-pool']
Queue URL: https://sqs.us-west-2.amazonaws.com/123456789/re-datahub-abc123
Starting Celery worker for queue: re-datahub-abc123
Worker ready to process tasks
```

## Configuration

### Essential Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `subscription_id` | Azure subscription ID | `"xxxx-xxxx"` |
| `resource_group_name` | Resource group with AKS | `"my-aks-rg"` |
| `aks_cluster_name` | AKS cluster name | `"my-aks-cluster"` |
| `datahub_gms_url` | DataHub GMS endpoint | `"https://company.acryl.io/gms"` |
| `datahub_access_token` | DataHub access token | `"<token>"` (sensitive) |
| `datahub_remote_executor_pool_id` | Executor pool ID | `"aks-executor-pool"` |

### Container Registry Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `container_registry_url` | Registry URL | `"docker.datahub.com/enterprise"` |
| `image_repository` | Full image path | `"docker.datahub.com/enterprise/datahub-executor"` |
| `image_tag` | Image version | `"v0.3.13-acryl"` |

### Network Variables (for Locked-Down Environments)

| Variable | Description | Default |
|----------|-------------|---------|
| `http_proxy` | HTTP proxy URL | `""` (disabled) |
| `https_proxy` | HTTPS proxy URL | `""` (disabled) |
| `no_proxy` | Proxy bypass list | `"localhost,127.0.0.1,.svc,.cluster.local"` |

### Resource Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `replica_count` | Number of executor pods | `1` |
| `resources_requests_cpu` | CPU request | `"250m"` |
| `resources_requests_memory` | Memory request | `"512Mi"` |
| `resources_limits_cpu` | CPU limit | `"500m"` |
| `resources_limits_memory` | Memory limit | `"1Gi"` |

## Azure AD Workload Identity

Workload Identity provides keyless authentication from AKS pods to Azure services (like ACR).

### Benefits

- No credentials in Kubernetes secrets
- Automatic token rotation by AKS
- Fine-grained access control via Azure RBAC
- Recommended for production deployments

### Requirements

- AKS cluster with OIDC issuer enabled (AKS 1.24+)
- Azure AD Workload Identity enabled on cluster

### Enable Workload Identity on Existing AKS

```bash
az aks update \
  --name my-aks-cluster \
  --resource-group my-aks-rg \
  --enable-oidc-issuer \
  --enable-workload-identity
```

### Configuration

```hcl
# terraform.tfvars
enable_workload_identity = true
azure_identity_name      = "datahub-executor-identity"
acr_name                 = "customername"
acr_resource_group_name  = "my-acr-rg"

# No need for registry username/password
container_registry_username = ""
container_registry_password = ""
```

This module automatically:
1. Creates Azure User Assigned Identity
2. Creates federated credential for service account
3. Grants AcrPull role to the identity
4. Annotates Kubernetes service account

## Troubleshooting

### Common Issues

#### 1. ImagePullBackOff

**Symptoms:**
```
kubectl get pods -n datahub-remote-executor
NAME                          READY   STATUS             RESTARTS   AGE
datahub-executor-xxx          0/1     ImagePullBackOff   0          2m
```

**Causes & Solutions:**

**a) Invalid ACR credentials:**
```bash
# Verify ACR access
az acr login --name customername

# Test image pull manually
docker pull customername.azurecr.io/datahub-executor:v0.3.13-acryl
```

**b) Workload Identity not configured:**
```bash
# Check if OIDC issuer is enabled
az aks show --name my-aks-cluster --resource-group my-aks-rg \
  --query "oidcIssuerProfile.enabled"

# Should return: true
```

**c) Missing AcrPull role:**
```bash
# Verify role assignment
az role assignment list \
  --assignee <identity-client-id> \
  --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.ContainerRegistry/registries/customername
```

#### 2. Connection Timeout to DataHub GMS

**Symptoms:**
```
Error: Failed to fetch executor configs from GMS
Connection timeout to https://company.acryl.io/gms
```

**Causes & Solutions:**

**a) Network connectivity issue:**
```bash
# Test connectivity from pod
kubectl run -n datahub-remote-executor -it --rm debug \
  --image=curlimages/curl --restart=Never \
  -- curl -v https://company.acryl.io/gms/health
```

**b) Proxy not configured:**
```hcl
# Add to terraform.tfvars
http_proxy  = "http://proxy.internal:8080"
https_proxy = "http://proxy.internal:8080"
```

**c) Firewall blocking traffic:**
- Verify NSG rules allow outbound 443 to DataHub GMS
- Check Azure Firewall or NVA rules

#### 3. AWS SQS Connection Failed

**Symptoms:**
```
Error connecting to SQS: Unable to connect to endpoint https://sqs.us-west-2.amazonaws.com
```

**Causes & Solutions:**

**a) No connectivity to AWS:**
```bash
# Test from pod
kubectl run -n datahub-remote-executor -it --rm debug \
  --image=curlimages/curl --restart=Never \
  -- curl -v https://sqs.us-west-2.amazonaws.com
```

**b) Proxy required but not configured:**
- Add proxy configuration (see Option C above)

**c) VPN/ExpressRoute routing issue:**
- Verify route tables in Azure and AWS
- Check BGP route propagation
- Test connectivity from AKS node directly

#### 4. Executor Not Registering with DataHub

**Symptoms:**
- Pods running but not visible in DataHub UI
- No tasks being processed

**Causes & Solutions:**

**a) Pool ID mismatch:**
```bash
# Check configured pool ID
kubectl get deployment -n datahub-remote-executor \
  datahub-executor-datahub-executor-worker -o yaml | grep POOL_ID
```

Must match the pool created in DataHub UI.

**b) Invalid DataHub token:**
```bash
# Test token manually
curl -H "Authorization: Bearer <token>" \
  https://company.acryl.io/gms/health
```

**c) Pool not in READY state:**
- Check pool status in DataHub UI → Settings → Executor Pools
- Pool must be in "READY" state, not "PROVISIONING_PENDING"

### Debugging Commands

The Terraform outputs provide useful debugging commands:

```bash
# Get all debugging commands
terraform output debugging_commands

# Check pods status
kubectl get pods -n datahub-remote-executor

# View executor logs
kubectl logs -n datahub-remote-executor \
  -l app.kubernetes.io/name=datahub-executor-worker --tail=100 -f

# Exec into pod
kubectl exec -n datahub-remote-executor -it \
  $(kubectl get pods -n datahub-remote-executor \
    -l app.kubernetes.io/name=datahub-executor-worker \
    -o jsonpath='{.items[0].metadata.name}') -- /bin/bash

# Test network connectivity from inside pod
kubectl run -n datahub-remote-executor -it --rm debug \
  --image=nicolaka/netshoot --restart=Never -- /bin/bash
```

### Network Connectivity Tests

Run these tests from a debug pod to verify connectivity:

```bash
# Test DataHub GMS (most critical - handles STS credentials too)
curl -v https://your-company.acryl.io/gms/health

# Test AWS SQS endpoint
curl -v https://sqs.us-west-2.amazonaws.com

# Test DNS resolution
nslookup your-company.acryl.io
nslookup sqs.us-west-2.amazonaws.com

# Test proxy (if configured)
curl -x $HTTP_PROXY -v https://sqs.us-west-2.amazonaws.com

# Note: No need to test sts.amazonaws.com - GMS handles all STS calls
```

## Security Considerations

### 1. Secrets Management

**Current Implementation:** Kubernetes native secrets
- DataHub access token stored in `kubernetes_secret.datahub_access_token`
- ACR credentials stored in `kubernetes_secret.container_registry` (if not using Workload Identity)

**Enhanced Options:**

**Azure Key Vault with CSI Driver:**
```bash
# Enable Azure Key Vault CSI driver on AKS
az aks enable-addons \
  --name my-aks-cluster \
  --resource-group my-aks-rg \
  --addons azure-keyvault-secrets-provider
```

**External Secrets Operator:**
- Deploy External Secrets Operator
- Configure SecretStore pointing to Azure Key Vault
- Replace `kubernetes_secret` resources with `ExternalSecret`

### 2. Network Security

**Network Policies:**
```yaml
# Restrict executor egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: executor-egress
  namespace: datahub-remote-executor
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: datahub-executor-worker
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 53  # DNS
  - to:
    - podSelector: {}  # Allow proxy access
    ports:
    - protocol: TCP
      port: 8080
```

**Azure Firewall:**
- Deploy Azure Firewall in hub VNet
- Route AKS egress through firewall
- Implement application rules for allowed FQDNs

### 3. Pod Security

The Helm chart enforces security best practices:
- Runs as non-root user (UID 1000)
- Read-only root filesystem (where possible)
- Drop all capabilities
- Security context enforcement

### 4. Access Control

**AKS RBAC:**
- Limit who can access executor namespace
- Use Azure AD integration for kubectl access
- Implement PodSecurityPolicy or Pod Security Standards

### 5. Audit Logging

**Enable AKS diagnostic logs:**
```bash
az monitor diagnostic-settings create \
  --name aks-diagnostics \
  --resource $(az aks show --name my-aks-cluster --resource-group my-aks-rg --query id -o tsv) \
  --logs '[{"category": "kube-audit", "enabled": true}]' \
  --workspace <log-analytics-workspace-id>
```

## Key Takeaways

1. **Helm Chart is Local** - No Helm repository access needed; chart included in module
2. **No AWS Credentials on Executor** - Uses DataHub GMS token; GMS provides temporary AWS STS credentials
3. **Minimal Egress Requirements** - Only 2 AWS endpoints: DataHub GMS and AWS SQS (HTTPS/443). GMS handles all AWS STS operations.
4. **Security Model** - All communication outbound; no inbound ports required
5. **Proxy Support** - Standard HTTP_PROXY/HTTPS_PROXY environment variables
6. **ACR Private Endpoint** - Complete air-gapped deployment possible with ACR private endpoint + VPN/ExpressRoute to AWS
7. **Workload Identity** - Recommended for keyless authentication to ACR

## Additional Resources

- [DataHub Documentation](https://datahubproject.io/docs/)
- [DataHub Remote Executor Guide](https://docs.datahub.com/docs/managed-datahub/remote-executor/about)
- [Azure AKS Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview)
- [Azure Private Link](https://learn.microsoft.com/en-us/azure/private-link/private-link-overview)

## Support

For issues related to:
- **Terraform configuration**: Check this documentation and Terraform logs
- **Helm chart**: Refer to Helm chart documentation in `datahub-executor-helm/`
- **DataHub Executor**: Check DataHub documentation and executor logs
- **AKS/Azure**: Consult Microsoft Azure documentation

