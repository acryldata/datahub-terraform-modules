# --- ALB  -----------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Allow inbound HTTPS from allowed CIDRs; outbound to Frontend service"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from allowed CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-alb-sg" }
}

# --- Frontend ECS service -----------------------------------------------------

resource "aws_security_group" "frontend" {
  name        = "${var.name}-frontend-sg"
  description = "Frontend ECS task security group"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound (GMS, ECR, Secrets Manager)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-frontend-sg" }
}

resource "aws_security_group_rule" "frontend_from_alb" {
  type                     = "ingress"
  from_port                = var.frontend_port
  to_port                  = var.frontend_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.frontend.id
  source_security_group_id = aws_security_group.alb.id
  description               = "Frontend port from ALB"
}

# --- GMS ECS service -----------------------------------------------------

resource "aws_security_group" "gms" {
  name        = "${var.name}-gms-sg"
  description = "GMS ECS task security group"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound (RDS, MSK, OpenSearch, ECR, Secrets Manager)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-gms-sg" }
}

resource "aws_security_group_rule" "gms_from_frontend" {
  type                     = "ingress"
  from_port                = var.gms_port
  to_port                  = var.gms_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.gms.id
  source_security_group_id = aws_security_group.frontend.id
  description               = "GMS port from Frontend"
}

resource "aws_security_group_rule" "gms_from_actions" {
  type                     = "ingress"
  from_port                = var.gms_port
  to_port                  = var.gms_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.gms.id
  source_security_group_id = aws_security_group.actions.id
  description               = "GMS port from Actions"
}

# --- Actions ECS service -----------------------------------------------------

resource "aws_security_group" "actions" {
  name        = "${var.name}-actions-sg"
  description = "Actions ECS task security group"
  vpc_id      = var.vpc_id

  egress {
    description = "All outbound (GMS, MSK, ECR, Secrets Manager)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-actions-sg" }
}

# --- RDS MySQL -----------------------------------------------------

resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "RDS MySQL security group"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-rds-sg" }
}

resource "aws_security_group_rule" "rds_from_gms" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.gms.id
  description               = "MySQL from GMS"
}

resource "aws_security_group_rule" "rds_from_system_update" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.system_update.id
  description               = "MySQL from the System Update task"
}

resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rds.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# --- MSK -----------------------------------------------------

resource "aws_security_group" "msk" {
  name        = "${var.name}-msk-sg"
  description = "MSK broker security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-msk-sg" }
}

resource "aws_security_group_rule" "msk_tls_from_gms" {
  type                     = "ingress"
  from_port                = 9094
  to_port                  = 9094
  protocol                 = "tcp"
  security_group_id        = aws_security_group.msk.id
  source_security_group_id = aws_security_group.gms.id
  description               = "Kafka TLS from GMS"
}

resource "aws_security_group_rule" "msk_tls_from_actions" {
  type                     = "ingress"
  from_port                = 9094
  to_port                  = 9094
  protocol                 = "tcp"
  security_group_id        = aws_security_group.msk.id
  source_security_group_id = aws_security_group.actions.id
  description               = "Kafka TLS from Actions"
}

# --- OpenSearch -----------------------------------------------------

resource "aws_security_group" "opensearch" {
  name        = "${var.name}-opensearch-sg"
  description = "OpenSearch domain security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-opensearch-sg" }
}

resource "aws_security_group_rule" "opensearch_https_from_gms" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.opensearch.id
  source_security_group_id = aws_security_group.gms.id
  description               = "HTTPS from GMS"
}

resource "aws_security_group_rule" "opensearch_https_from_system_update" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.opensearch.id
  source_security_group_id = aws_security_group.system_update.id
  description               = "HTTPS from the System Update task"
}

# --- System Update (one-time task) -----------------------------------------------------

resource "aws_security_group" "system_update" {
  name        = "${var.name}-system-update-sg"
  description = "System Update (datahub-upgrade) one-time ECS task security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name}-system-update-sg" }
}
