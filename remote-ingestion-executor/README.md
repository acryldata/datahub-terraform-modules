# DataHub Remote Ingestion Executor Terraform Module

This Terraform module deploys the DataHub Remote Ingestion Executor on AWS ECS, supporting both Fargate and EC2 launch types.

## Features

- **Dual Launch Type Support**: Deploy on either ECS Fargate or EC2
- **Existing Infrastructure Integration**: Uses your existing subnets and networking
- **Minimal Configuration Changes**: The same module works for both deployment types
- **Production Ready**: Includes proper IAM roles, security groups, and logging

## Quick Start

### 1. Choose Your Deployment Type

**Fargate (Recommended for simplicity):**
```hcl
module "datahub_remote_executor" {
  source = "path/to/this/module"
  
  cluster_name = "datahub-remote-executor-fargate"
  launch_type  = "FARGATE"
  
  datahub = {
    url              = "https://your-company.acryl.io/gms"
    executor_pool_id = "ecs-executor-pool"
  }
  
  # Fargate-specific settings
  cpu              = 1024
  memory           = 2048
  subnet_ids       = ["subnet-xxx", "subnet-yyy"]
  assign_public_ip = true
  
  # ... other configuration
}
```

**EC2 (Recommended for cost optimization):**
```hcl
module "datahub_remote_executor" {
  source = "path/to/this/module"
  
  cluster_name = "datahub-remote-executor-ec2"
  launch_type  = "EC2"
  
  datahub = {
    url              = "https://your-company.acryl.io/gms"
    executor_pool_id = "ecs-ec2-executor-pool"
  }
  
  # EC2-specific settings
  cpu    = 512
  memory = 1024
  
  ec2_config = {
    private_subnet_ids = ["subnet-xxx", "subnet-yyy", "subnet-zzz"]
    instance_type      = "t3.large"
  }
  
  # ... other configuration
}
```

### 2. Use the Examples

Complete example configurations are available in the [`examples/`](./examples/) directory:

- [`examples/fargate.tfvars`](./examples/fargate.tfvars) - Fargate deployment
- [`examples/ec2.tfvars`](./examples/ec2.tfvars) - EC2 deployment

```bash
cd examples/
terraform init
terraform plan -var-file=ec2.tfvars  # or fargate.tfvars
terraform apply -var-file=ec2.tfvars
```

## Key Differences

| Aspect | Fargate | EC2 |
|--------|---------|-----|
| **Infrastructure** | Uses existing public subnets | Uses existing private subnets |
| **Management** | Fully managed | Self-managed single instance |
| **Cost** | Higher for 24/7 workloads | Lower for constant workloads |
| **Security** | Public subnets + public IPs | Private subnets + NAT Gateway |
| **Setup** | Requires public subnet IDs | Requires private subnet IDs |

## Module Architecture

### For EC2 Launch Type
When `launch_type = "EC2"`, the module creates:
- Single EC2 instance with ECS-optimized AMI
- Security groups for EC2 instance
- IAM roles for EC2 instance
- Uses your existing private subnets with NAT Gateway connectivity

### For Fargate Launch Type
When `launch_type = "FARGATE"`, the module uses:
- Your existing public subnets
- Public IP assignment for internet access
- No additional infrastructure creation

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| ecs_cluster | terraform-aws-modules/ecs/aws//modules/cluster | 5.9.2 |
| ecs_service | terraform-aws-modules/ecs/aws//modules/service | 5.9.2 |
| ec2_infrastructure | ./modules/ec2-infrastructure | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the ECS cluster | `string` | n/a | yes |
| datahub | DataHub configuration | `object({...})` | n/a | yes |
| launch_type | Launch type (EC2 or FARGATE) | `string` | `"FARGATE"` | no |
| ec2_config | EC2-specific configuration | `object({...})` | `{}` | no |
| subnet_ids | Subnet IDs (Fargate only) | `list(string)` | `[]` | no |
| assign_public_ip | Assign public IP (Fargate only) | `bool` | `false` | no |

See [`variables.tf`](./variables.tf) for complete input documentation.

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | Name of the ECS cluster |
| cluster_arn | ARN of the ECS cluster |
| service_name | Name of the ECS service |
| task_definition_arn | ARN of the task definition |
| private_subnet_ids | Private subnet IDs used (EC2 only) |
| instance_id | EC2 instance ID (EC2 only) |

## License

This module is provided under the same license as the DataHub project.