locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "redis"
    }
  )
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = local.common_tags
}

resource "aws_elasticache_parameter_group" "this" {
  name        = "${var.name}-parameters"
  family      = var.parameter_group_family
  description = "Redis parameters for ${var.name}"

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "redis" {
  #checkov:skip=CKV_AWS_338:Redis log retention is configurable by environment to balance operational visibility and development cost.
  for_each = toset([
    "engine-log",
    "slow-log"
  ])

  name              = "/aws/elasticache/${var.name}/${each.value}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = local.common_tags
}

resource "aws_elasticache_replication_group" "this" {
  #checkov:skip=CKV2_AWS_50:Multi-AZ automatic failover is configurable by environment; production enables it with two cache nodes while development uses one node for cost control.
  replication_group_id = var.name
  description          = "Redis replication group for ${var.name}"

  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = 6379
  parameter_group_name = aws_elasticache_parameter_group.this.name

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [var.security_group_id]

  num_cache_clusters         = var.num_cache_clusters
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  at_rest_encryption_enabled = true
  kms_key_id                 = var.kms_key_arn

  transit_encryption_enabled = true
  transit_encryption_mode    = "required"
  auth_token                 = var.auth_token

  snapshot_retention_limit = var.snapshot_retention_limit

  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis["engine-log"].name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis["slow-log"].name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  depends_on = [
    aws_cloudwatch_log_group.redis
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
        !var.automatic_failover_enabled ||
        var.num_cache_clusters >= 2
      )

      error_message = "automatic_failover_enabled requires at least two cache nodes."
    }

    precondition {
      condition = (
        !var.multi_az_enabled ||
        var.num_cache_clusters >= 2
      )

      error_message = "multi_az_enabled requires at least two cache nodes."
    }
  }
}