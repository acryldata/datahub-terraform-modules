resource "aws_kms_key" "msk" {
  description             = "${var.name} MSK encryption at rest"
  deletion_window_in_days = 7
}

resource "aws_msk_cluster" "this" {
  cluster_name           = "${var.name}-msk"
  kafka_version           = var.msk_kafka_version
  number_of_broker_nodes  = var.msk_number_of_broker_nodes

  broker_node_group_info {
    instance_type   = var.msk_instance_type
    client_subnets  = var.private_subnet_ids
    security_groups = [var.msk_sg_id]

    storage_info {
      ebs_storage_info {
        volume_size = var.msk_ebs_volume_size
      }
    }
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = aws_kms_key.msk.arn

    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  tags = { Name = "${var.name}-msk" }
}
