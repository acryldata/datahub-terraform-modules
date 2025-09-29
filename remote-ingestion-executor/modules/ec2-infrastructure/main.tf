# EC2 Infrastructure Module for DataHub Remote Ingestion Executor
# This module creates EC2-specific infrastructure (Auto Scaling Group and Launch Template)
# It uses existing private subnets and NAT Gateways instead of creating new ones

# Data source for AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# Data source to get VPC information from provided subnets
data "aws_subnet" "private" {
  count = length(var.private_subnet_ids)
  id    = var.private_subnet_ids[count.index]
}

# Security group for EC2 instances
resource "aws_security_group" "ecs_instances" {
  name_prefix = "${var.cluster_name}-ecs-instances-"
  vpc_id      = data.aws_subnet.private[0].vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ecs-instances-sg"
  })
}

# IAM role for ECS instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "${var.cluster_name}-ecs-instance-role"

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

  tags = var.tags
}

# Attach ECS instance policy
resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Create instance profile
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "${var.cluster_name}-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# EC2 instance for ECS
resource "aws_instance" "ecs_instance" {
  ami           = data.aws_ami.ecs_optimized.id
  instance_type = var.instance_type
  subnet_id     = var.private_subnet_ids[0]  # Use first subnet
  
  vpc_security_group_ids = [aws_security_group.ecs_instances.id]
  iam_instance_profile   = aws_iam_instance_profile.ecs_instance_profile.name
  
  # Explicit EBS configuration to avoid SCP issues
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
    
    tags = merge(var.tags, {
      Name = "${var.cluster_name}-ecs-instance-root"
    })
  }
  
  user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
    cluster_name = var.cluster_name
  }))

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-ecs-instance"
  })
}
