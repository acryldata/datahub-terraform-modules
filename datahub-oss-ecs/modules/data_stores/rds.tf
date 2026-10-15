resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.name}-db-subnet-group" }
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name}-mysql"
  engine         = "mysql"
  engine_version = var.db_engine_version

  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  manage_master_user_password = true
  port     = 3306

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = false

  backup_retention_period = var.db_backup_retention_days
  skip_final_snapshot     = true
  deletion_protection     = false # reference deployment default — enable for production use

  tags = { Name = "${var.name}-mysql" }
}

# RDS creates and manages the master password secret (JSON keys: username, password) and
# rotates it every 7 days by default. The ECS tasks read the password at start-up and do not
# pick up a rotated value, so rotation would break GMS's database connection until the tasks
# are restarted. Rotation cannot be switched off from the aws_db_instance resource, so this sets
# a long schedule on the managed secret instead. rotate_immediately = false avoids forcing a
# rotation when the schedule is applied. Requires an AWS provider version where
# rotation_lambda_arn is optional for AWS-managed secrets.
resource "aws_secretsmanager_secret_rotation" "db_master" {
  secret_id          = aws_db_instance.this.master_user_secret[0].secret_arn
  rotate_immediately = false

  rotation_rules {
    automatically_after_days = var.db_master_password_rotation_days
  }
}

# ARN of the RDS-managed secret. ECS tasks reference it as "<arn>:password::".
output "db_master_secret_arn" {
  value = aws_db_instance.this.master_user_secret[0].secret_arn
}
