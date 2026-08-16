locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "runtime"
    }
  )

  database_url = format(
    "postgresql+psycopg://%s:%s@%s:%s/%s?sslmode=require",
    urlencode(var.database_username),
    urlencode(var.database_password),
    var.database_host,
    var.database_port,
    urlencode(var.database_name)
  )

  redis_url = format(
    "rediss://:%s@%s:%s/0",
    urlencode(var.redis_auth_token),
    var.redis_host,
    var.redis_port
  )
}

resource "aws_secretsmanager_secret" "runtime" {
  name                    = "${var.name}/application/runtime"
  description             = "Runtime connection configuration for ${var.name}"
  kms_key_id              = var.kms_key_arn
  recovery_window_in_days = var.secret_recovery_window_days

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "runtime" {
  secret_id = aws_secretsmanager_secret.runtime.id

  secret_string = jsonencode({
    DATABASE_URL = local.database_url
    REDIS_URL    = local.redis_url
  })
}