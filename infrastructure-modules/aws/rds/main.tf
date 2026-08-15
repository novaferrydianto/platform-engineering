locals {
  tags = merge(var.tags, { Name = var.name, ManagedBy = "opentofu" })
  port = var.engine == "postgres" ? 5432 : 3306
}

resource "aws_kms_key" "rds" {
  description             = "RDS storage and secret encryption for ${var.name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = local.tags
}

resource "aws_kms_alias" "rds" {
  name          = "alias/rds-${var.name}"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.private_subnet_ids
  tags       = local.tags
}

resource "aws_security_group" "this" {
  name        = "${var.name}-rds"
  description = "Database access for ${var.name}"
  vpc_id      = var.vpc_id
  tags        = merge(local.tags, { Name = "${var.name}-rds" })

  lifecycle {
    create_before_destroy = true
  }
}

# Deny-all until a caller is named. No CIDR ingress and no egress rules at all —
# a database has no reason to originate outbound connections.
resource "aws_vpc_security_group_ingress_rule" "from_allowed" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.this.id
  description                  = "Database traffic from ${each.value}"
  referenced_security_group_id = each.value
  from_port                    = local.port
  to_port                      = local.port
  ip_protocol                  = "tcp"
}

resource "aws_db_parameter_group" "this" {
  name   = var.name
  family = var.engine == "postgres" ? "postgres16" : "mysql8.0"
  tags   = local.tags

  dynamic "parameter" {
    for_each = var.engine == "postgres" ? [1] : []

    content {
      name  = "rds.force_ssl"
      value = "1"
    }
  }

  dynamic "parameter" {
    for_each = var.engine == "mysql" ? [1] : []

    content {
      name  = "require_secure_transport"
      value = "ON"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name               = "${var.name}-rds-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  db_name  = var.database_name
  username = var.master_username
  port     = local.port

  # AWS generates and rotates the master password into Secrets Manager. No
  # password ever passes through OpenTofu state or a tfvars file.
  manage_master_user_password   = true
  master_user_secret_kms_key_id = aws_kms_key.rds.key_id

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window           = "17:00-18:00"
  maintenance_window      = "sun:18:30-sun:19:30"
  copy_tags_to_snapshot   = true

  auto_minor_version_upgrade = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${var.name}-final"

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = 7

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.monitoring.arn

  enabled_cloudwatch_logs_exports = var.engine == "postgres" ? ["postgresql", "upgrade"] : ["error", "general", "slowquery"]

  iam_database_authentication_enabled = true

  tags = local.tags

  lifecycle {
    ignore_changes = [engine_version] # minor upgrades are applied in the maintenance window
  }
}
