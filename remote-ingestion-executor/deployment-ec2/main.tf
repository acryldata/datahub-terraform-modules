# Deploy DataHub Remote Ingestion Executor on AWS ECS EC2
terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}

# Get default VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data source for public subnets (for NAT Gateway)
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# Data source for internet gateway
data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get the latest ECS-optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# NAT Gateway resources for internet access
resource "aws_eip" "nat_gateway" {
  domain = "vpc"
  
  tags = {
    Name        = "nat-gateway-eip-ec2"
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "datahub-remote-executor"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = data.aws_subnets.public.ids[0]  # Use first public subnet
  
  tags = {
    Name        = "nat-gateway-ec2"
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "datahub-remote-executor"
  }

  depends_on = [data.aws_internet_gateway.default]
}

# Create a custom route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "private-route-table-ec2"
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "datahub-remote-executor"
  }
}

# Create private subnets for ECS tasks
resource "aws_subnet" "private" {
  count = 2
  
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = cidrsubnet(data.aws_vpc.default.cidr_block, 8, count.index + 100)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = false
  
  tags = {
    Name        = "private-subnet-ec2-${count.index + 1}"
    Environment = "production"
    ManagedBy   = "terraform"
    Project     = "datahub-remote-executor"
    Type        = "private"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Create security group for EC2 instances
resource "aws_security_group" "ecs_instances" {
  name_prefix = "ecs-instances-"
  vpc_id      = data.aws_vpc.default.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic from ALB (if needed later)
  ingress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  tags = {
    Name        = "ecs-instances-sg"
    Environment = "dev"
    Project     = "datahub-remote-executor"
    ManagedBy   = "terraform"
  }
}

# IAM role for ECS instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = "dev"
    Project     = "datahub-remote-executor"
    ManagedBy   = "terraform"
  }
}

# Attach ECS instance policy
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Create instance profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# Launch template for ECS instances
resource "aws_launch_template" "ecs_instances" {
  name_prefix   = "ecs-instances-"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t3.large"

  # Network interface configuration for private subnets
  network_interfaces {
    associate_public_ip_address = false  # Private subnets use NAT Gateway
    security_groups             = [aws_security_group.ecs_instances.id]
    delete_on_termination       = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = "datahub-remote-executor-ec2"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "ecs-instance"
      Environment = "dev"
      Project     = "datahub-remote-executor"
      ManagedBy   = "terraform"
    }
  }

  tags = {
    Environment = "dev"
    Project     = "datahub-remote-executor"
    ManagedBy   = "terraform"
  }
}

# Auto Scaling Group for ECS instances
resource "aws_autoscaling_group" "ecs_instances" {
  name                      = "ecs-instances-asg"
  vpc_zone_identifier       = aws_subnet.private[*].id  # Use private subnets with NAT Gateway
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.ecs_instances.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "dev"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "datahub-remote-executor"
    propagate_at_launch = true
  }

  tag {
    key                 = "ManagedBy"
    value               = "terraform"
    propagate_at_launch = true
  }
}

# Deploy the DataHub Remote Ingestion Executor
module "datahub_remote_executor" {
  source = "../"

  cluster_name = "datahub-remote-executor-ec2"

  datahub = {
    url                              = "https://test-environment.acryl.io/gms"
    executor_pool_id                 = "ecs-ec2-executor-pool"
    executor_ingestions_workers      = 4
    executor_monitors_workers        = 10
    executor_ingestions_poll_interval = 5
  }

  service_name   = "datahub-remote-executor-ec2"
  desired_count  = 1

  # EC2 launch type configuration
  cpu    = 512   # Lower values for EC2 (instance-level resources)
  memory = 1024  # 1GB memory

  # Network configuration - using awsvpc mode for EC2 (same as Fargate)
  network_mode = "awsvpc"
  
  # Use private subnets with NAT Gateway for internet access
  subnet_ids = aws_subnet.private[*].id
  assign_public_ip = false  # Not needed with NAT Gateway

  # Security group configuration
  security_group_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  create_tasks_iam_role     = true
  create_task_exec_iam_role = true

  task_exec_secret_arns = [
    "arn:aws:secretsmanager:us-west-2:863541928889:secret:datahub-access-token-xw7EfB"
  ]

  secrets = [
    {
      name      = "DATAHUB_GMS_TOKEN"
      valueFrom = "arn:aws:secretsmanager:us-west-2:863541928889:secret:datahub-access-token-xw7EfB"
    }
  ]

  enable_cloudwatch_logging   = true
  create_cloudwatch_log_group = true
  enable_execute_command      = true

  # EC2 launch type configuration
  launch_type              = "EC2"
  requires_compatibilities = ["EC2"]

  # Environment variables for optimal performance
  environment = [
    {
      name  = "DATAHUB_DEBUG"
      value = "false"  # Set to false for production
    },
    {
      name  = "CELERY_LOG_LEVEL"
      value = "INFO"    # INFO level for production
    },
    {
      name  = "PYTHONUNBUFFERED"
      value = "1"
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "datahub-remote-executor"
    ManagedBy   = "terraform"
  }
}

# Output important information
output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.datahub_remote_executor.cluster_name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.datahub_remote_executor.cluster_arn
}

output "service_name" {
  description = "Name of the ECS service"
  value       = module.datahub_remote_executor.service_name
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = module.datahub_remote_executor.task_definition_arn
}

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.ecs_instances.name
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.ecs_instances.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT Gateway"
  value       = aws_eip.nat_gateway.public_ip
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}
