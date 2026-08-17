locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "rds"
    }
  )
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-subnet-group"
    }
  )
}

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.name}-"
  family      = var.parameter_group_family
  description = "PostgreSQL parameters for ${var.name}"

  dynamic "parameter" {
    for_each = var.database_parameters

    content {
      name         = parameter.key
      value        = parameter.value
      apply_method = "pending-reboot"
    }
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}



#checkov:skip=CKV_AWS_338:Log retention is configurable by environment; production uses the approved retention period while development uses a shorter cost-controlled period.
resource "aws_cloudwatch_log_group" "rds" {
  for_each = var.log_exports

  name              = "/aws/rds/instance/${var.name}/${each.value}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = local.common_tags
}

data "aws_iam_policy_document" "enhanced_monitoring_assume_role" {
  count = var.monitoring_interval > 0 ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "monitoring.rds.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name               = "${var.name}-enhanced-monitoring"
  assume_role_policy = data.aws_iam_policy_document.enhanced_monitoring_assume_role[0].json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

#checkov:skip=CKV_AWS_157:Multi-AZ is configurable by environment; production enables it while development uses single-AZ for cost control.
#checkov:skip=CKV_AWS_353:Performance Insights is configurable because enabling it may add cost; CloudWatch metrics and database logs remain available.
resource "aws_db_instance" "this" {
  identifier = var.name

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = var.database_name
  username = var.database_username
  password = var.database_password
  port     = 5432

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  parameter_group_name = aws_db_parameter_group.this.name

  backup_retention_period = var.backup_retention_days
  copy_tags_to_snapshot   = true

  enabled_cloudwatch_logs_exports = var.log_exports

  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_kms_key_id = (
    var.performance_insights_enabled ? var.kms_key_arn : null
  )

  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = (
    var.monitoring_interval > 0
    ? aws_iam_role.enhanced_monitoring[0].arn
    : null
  )

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = var.apply_immediately

  iam_database_authentication_enabled = true

  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : var.final_snapshot_identifier

  delete_automated_backups = true

  depends_on = [
    aws_cloudwatch_log_group.rds
  ]

  tags = merge(
    local.common_tags,
    {
      Name = var.name
    }
  )

  lifecycle {
    precondition {
      condition = (
        var.skip_final_snapshot ||
        var.final_snapshot_identifier != null
      )

      error_message = "final_snapshot_identifier must be provided when skip_final_snapshot is false."
    }
  }
}