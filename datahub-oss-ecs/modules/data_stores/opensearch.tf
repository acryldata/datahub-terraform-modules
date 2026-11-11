resource "aws_opensearch_domain" "this" {
  domain_name    = "${var.name}-search"
  engine_version = var.opensearch_engine_version

  cluster_config {
    instance_type          = var.opensearch_instance_type
    instance_count          = var.opensearch_instance_count
    zone_awareness_enabled = true

    zone_awareness_config {
      availability_zone_count = length(var.private_subnet_ids)
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = var.opensearch_ebs_volume_size
  }

  vpc_options {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [var.opensearch_sg_id]
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  advanced_security_options {
    enabled                        = false
    internal_user_database_enabled = false
  }

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = [var.gms_task_role_arn]
        }
        Action   = "es:ESHttp*"
        Resource = "arn:aws:es:${var.aws_region}:${var.account_id}:domain/${var.name}-search/*"
      }
    ]
  })

  tags = { Name = "${var.name}-search" }
}

data "aws_iam_policy_document" "gms_task_opensearch" {
  statement {
    sid    = "OpenSearchHttpAccess"
    effect = "Allow"
    actions = [
      "es:ESHttpGet",
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:ESHttpDelete",
      "es:ESHttpHead",
    ]
    resources = ["${aws_opensearch_domain.this.arn}/*"]
  }
}

resource "aws_iam_role_policy" "gms_task_opensearch" {
  name   = "${var.name}-opensearch-access"
  role   = var.gms_task_role_name
  policy = data.aws_iam_policy_document.gms_task_opensearch.json
}
