# DataHub Remote Executor on GKE

This repository contains Terraform configuration and sample resources for deploying DataHub Remote Executor to Google Kubernetes Engine (GKE) with custom transformers support.

## 🏗️ Repository Structure

```
.
├── README.md                           # This file
├── docs/                              # Documentation
├── sample/                           # Sample configurations and transformers
│   └── sample-setup.md               # Sample data source and transformer setup guide
│   ├── transformers/                 # Custom transformer examples
│   │   ├── custom_transform_example.py
│   │   ├── setup.py
│   │   └── owners.json
│   └── source/                       # Sample data source configurations
│       ├── postgres-config.yaml
│       ├── postgres-deployment.yaml
│       └── postgres-recipe.yaml
├── datahub-executor-helm/            # Helm chart for DataHub executor
│   └── charts/
│       └── datahub-executor-worker/
├── main.tf                          # Main Terraform configuration
├── variables.tf                     # Variable definitions
├── outputs.tf                       # Output definitions
├── versions.tf                      # Provider version constraints
├── helm-values.yaml.tpl             # Helm values template
├── terraform.tfvars.example         # Example variables file
├── .gitignore                       # Git ignore rules
└── deploy.sh                        # Quick deployment script
```

## 🚀 Quick Start

### Prerequisites

1. **GCP Project and GKE Cluster**: Ensure you have a GCP project with an existing GKE cluster
2. **Terraform**: Install Terraform >= 1.0
3. **gcloud CLI**: Install and authenticate with `gcloud auth application-default login`
4. **kubectl**: Install kubectl for cluster management
5. **DataHub Instance**: Access to a DataHub instance with API token

### 1. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
# Required variables
project_id     = "your-gcp-project-id"
cluster_name   = "your-gke-cluster-name"
region         = "us-central1"

# DataHub Configuration
datahub_gms_url      = "https://your-datahub-instance.com/gms"
datahub_access_token = "your-datahub-access-token"

# Container Registry Configuration
container_registry_url      = "gcr.io/your-project-id"
container_registry_username = "_json_key"
container_registry_password = "your-service-account-key-json"

# Custom Transformers (automatically enabled when path is set)
custom_transformers_path = "sample/transformers"  # Set to "" to disable
```

### 2. Deploy

Initialize and apply Terraform:

```bash
terraform init
terraform plan
terraform apply
```

### 3. Verify Deployment

Check that the executor is running:

```bash
# Get kubectl configuration
gcloud container clusters get-credentials your-cluster-name --region your-region --project your-project-id

# Check pods
kubectl get pods -n datahub-remote-executor

# View logs
kubectl logs -n datahub-remote-executor -l app.kubernetes.io/name=datahub-executor-worker --tail=50
```

## 🔧 Configuration Options

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `project_id` | GCP project ID | `"my-project-123"` |
| `cluster_name` | Existing GKE cluster name | `"my-gke-cluster"` |
| `datahub_gms_url` | DataHub GMS endpoint | `"https://datahub.company.com/gms"` |
| `datahub_access_token` | DataHub access token | `"your-token"` |
| `container_registry_password` | Registry password/key | `"service-account-json"` |

### Optional Variables with Defaults

| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `"us-central1"` | GCP region |
| `kubernetes_namespace` | `"datahub-remote-executor"` | K8s namespace |
| `environment` | `"dev"` | Environment (dev/test/prod) |
| `datahub_remote_executor_pool_id` | `"gke-executor-pool"` | Executor pool ID |
| `replica_count` | `1` | Number of replicas |
| `custom_transformers_path` | `"sample/transformers"` | Path to custom transformers |

## 🔄 Custom Transformers

The repository includes built-in support for custom DataHub transformers:

### Automatic Enablement
Custom transformers are automatically enabled when `custom_transformers_path` is set to a non-empty value.

### Transformer Structure
Place your transformer files in the specified directory:
```
sample/transformers/
├── custom_transform_example.py  # Your transformer code
├── setup.py                    # Python package setup
└── owners.json                 # Configuration files
```

### Disabling Transformers
Set `custom_transformers_path = ""` in your `terraform.tfvars` to disable custom transformers.

## 🐘 Sample Data Source

The repository includes a sample PostgreSQL setup in `sample/source/` for testing purposes. See [Sample Setup Guide](docs/sample-setup.md) for detailed instructions on:

- Setting up a PostgreSQL data source
- Configuring ingestion recipes
- Using custom transformers
- Testing the complete pipeline

## 🏗️ Architecture

### Components

1. **GKE Cluster**: Kubernetes cluster hosting the executor
2. **DataHub Executor**: Remote executor pods processing ingestion tasks
3. **ConfigMaps**: Store custom transformer code and configuration
4. **Secrets**: Secure storage for DataHub tokens and registry credentials
5. **Custom Transformers**: Optional Python modules for data transformation

### Flow

1. DataHub schedules ingestion tasks to the remote executor pool
2. Executor pods pull tasks from the queue
3. Custom transformers are automatically installed via init containers
4. Ingestion runs with custom transformations applied
5. Results are sent back to DataHub

## 🔐 Security Considerations

1. **Secrets Management**: Sensitive values stored in Kubernetes secrets
2. **Network Security**: Configure appropriate network policies
3. **RBAC**: Service account with minimal required permissions
4. **Workload Identity**: Optional for enhanced security (set `enable_workload_identity = true`)
5. **Image Security**: Regular image updates and vulnerability scanning

## 🛠️ Troubleshooting

### Common Issues

1. **ImagePullBackOff**: Check container registry credentials
2. **CrashLoopBackOff**: Verify DataHub GMS URL and access token
3. **Pending Pods**: Check node resources and tolerations
4. **Transformer Installation Failures**: Check transformer setup.py syntax

### Debugging Commands

The Terraform outputs provide useful debugging commands:

```bash
# Check pods
kubectl get pods -n datahub-remote-executor

# View executor logs
kubectl logs -n datahub-remote-executor -l app.kubernetes.io/name=datahub-executor-worker --tail=100

# Check secrets
kubectl get secrets -n datahub-remote-executor

# Describe deployment
kubectl describe deployment datahub-executor-datahub-executor-worker -n datahub-remote-executor
```

## 🧹 Cleanup

To remove all resources:

```bash
terraform destroy
```

## 📚 Additional Resources

- [DataHub Documentation](https://datahubproject.io/docs/)
- [DataHub Remote Executor Guide](https://datahubproject.io/docs/managed-datahub/operator-guide/setting-up-remote-ingestion-executor)
- [Custom Transformers Documentation](https://datahubproject.io/docs/metadata-ingestion/docs/transformer/intro)
- [Sample Setup Guide](docs/sample-setup.md)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues related to:
- **Terraform configuration**: Check this documentation and Terraform logs
- **Helm chart**: Refer to the Helm chart documentation in `datahub-executor-helm/`
- **DataHub Executor**: Check DataHub documentation and executor logs
- **GKE/GCP**: Consult Google Cloud documentation
