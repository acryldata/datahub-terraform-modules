# DataHub Remote Ingestion Executor Examples

This directory contains example configurations for deploying the DataHub Remote Ingestion Executor on both AWS ECS Fargate and EC2.

## Quick Start

### 1. Choose Your Deployment Type

**Fargate (Recommended for simplicity):**
- Serverless containers
- No infrastructure management
- Higher cost for constant workloads
- Uses existing public subnets

**EC2 (Recommended for cost optimization):**
- Self-managed EC2 instance
- Uses existing private subnets with NAT Gateway connectivity
- Lower cost for constant workloads
- Enhanced security with private networking

### 2. Configure Your Deployment

Copy the appropriate `.tfvars` file and customize it:

```bash
# For Fargate deployment
cp fargate.tfvars terraform.tfvars

# For EC2 deployment  
cp ec2.tfvars terraform.tfvars
```

**Required Changes:**
1. Update `datahub.url` with your DataHub instance URL
2. Replace secret ARNs with your actual AWS Secrets Manager ARNs
3. For Fargate: Update `subnet_ids` with your actual subnet IDs
4. For EC2: Update `ec2_config.private_subnet_ids` with your actual private subnet IDs
5. Adjust resource sizing based on your needs

### 3. Deploy

```bash
terraform init
terraform plan -var-file=ec2.tfvars  # or fargate.tfvars
terraform apply -var-file=ec2.tfvars
```

## Configuration Details

### Fargate Configuration (`fargate.tfvars`)

Key settings:
- `launch_type = "FARGATE"`
- Higher CPU/memory allocation (1024/2048)
- Public IP assignment enabled
- Requires existing subnet IDs

### EC2 Configuration (`ec2.tfvars`)

Key settings:
- `launch_type = "EC2"`
- Lower task-level CPU/memory (512/1024)
- Uses existing private subnets with NAT Gateway connectivity
- Requires private subnet IDs configuration

The EC2 configuration creates:
- Single EC2 instance with ECS-optimized AMI
- Security groups and IAM roles
- Uses existing private subnets and NAT Gateway for internet access

## Outputs

Both configurations provide these outputs:
- `cluster_name` - ECS cluster name
- `cluster_arn` - ECS cluster ARN
- `service_name` - ECS service name
- `task_definition_arn` - Task definition ARN

EC2 configuration additionally provides:
- `private_subnet_ids` - IDs of the private subnets used
- `instance_id` - ID of the EC2 instance

## Cost Considerations

### Fargate
- Pay per task resource usage
- No infrastructure overhead
- More expensive for 24/7 workloads

### EC2
- Pay for single EC2 instance (uses existing NAT Gateway)
- More cost-effective for constant workloads
- Minimal infrastructure management

## Security

### Fargate
- Tasks run in public subnets with public IPs
- Direct internet access

### EC2
- Tasks run in private subnets
- Internet access via existing NAT Gateway
- Enhanced security isolation

## Troubleshooting

1. **Secret Access Issues**: Ensure your Secrets Manager ARNs are correct and the execution role has access
2. **Network Issues**: For Fargate, verify subnet IDs and security groups; for EC2, verify private subnet IDs have NAT Gateway connectivity
3. **Task Placement Issues**: For EC2, ensure the EC2 instance has launched and registered with ECS

## Support

For issues specific to the DataHub Remote Ingestion Executor, consult the DataHub documentation or contact your Acryl representative.
