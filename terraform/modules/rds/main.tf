locals {
  db_host = aws_db_instance.rds_db.endpoint
  is_prod = var.environment == "prod1" || var.environment == "prod2" ? true : false
  rds_identifier = "${var.environment}-${var.database_name}"
  rds_subnet_group_name = "${var.environment}-${var.database_name}-subnet-group"
  rds_sg_name = "${var.environment}-${var.database_name}-sg"
  port = var.rds_config.engine == "mysql" ? 3306 : 5432
  snapshot_identifier = var.latest_snapshot ? data.aws_db_snapshot.latest_rds_snapshot[0].id : var.named_snapshot ? var.rds_config.snapshot_id : null
}


resource "aws_db_instance" "rds_db" {
  allocated_storage = var.rds_config.allocated_storage
  engine            = var.rds_config.engine
  engine_version    = var.rds_config.engine_version
  instance_class    = var.rds_config.instance_class
  identifier        = local.rds_identifier
  # db_name           = local.rds_identifier
  // not defined for multi-az instances
  //  availability_zone    = [for s in data.aws_subnet.specific_private_airflow_subnet: s.availability_zone][0]
  backup_retention_period         = 7
  backup_window                   = "09:35-10:05"
  maintenance_window              = "sat:17:00-sat:17:30"
  copy_tags_to_snapshot           = true
  delete_automated_backups        = false
  deletion_protection             = false
  enabled_cloudwatch_logs_exports = var.rds_config.enabled_cloudwatch_logs_exports
  multi_az                        = false
  publicly_accessible             = false
  username                        = var.rds_username
  password                        = var.rds_password
  db_subnet_group_name            = aws_db_subnet_group.rds_private_subnet_group.name
  parameter_group_name            = var.rds_config.parameter_group_name
  skip_final_snapshot             = false
  final_snapshot_identifier       = "${local.rds_identifier}-final-${formatdate("YYYYMMDDHHmmss", timestamp())}"
  storage_encrypted               = true
  snapshot_identifier             = local.snapshot_identifier
  vpc_security_group_ids          = [aws_security_group.rds_db_sg.id]
  tags = {
    Name = local.rds_identifier
  }

  lifecycle {
    ignore_changes = [snapshot_identifier, final_snapshot_identifier]
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "rds_private_subnet_group" {
  name       = local.rds_subnet_group_name
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = local.rds_subnet_group_name
  }
}

data "aws_db_snapshot" "latest_rds_snapshot" {
  count = var.latest_snapshot ? 1 : 0
  db_instance_identifier = local.rds_identifier
  most_recent = true
}

resource "aws_security_group" "rds_db_sg" {
  name        = local.rds_sg_name
  description = "Security Group that allows internal aws services to hit RDS"
  vpc_id      = var.vpc_id

  ingress {
    description = "Self-referencing"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }
  ingress {
    description     = "Allow Nomad cluster to connect to RDS"
    from_port       = local.port
    protocol        = "TCP"
    to_port         = local.port
    security_groups = [var.nomad_security_group]
  }
  ingress {
    description     = "Allow Bastion to connect to RDS"
    from_port       = local.port
    protocol        = "TCP"
    to_port         = local.port
    security_groups = [var.bastion_security_group]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  tags = {
    Name = local.rds_sg_name
  }
}
