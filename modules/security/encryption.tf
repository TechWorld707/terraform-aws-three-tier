resource "aws_kms_key" "application" {
  description             = "Encrypts application secrets and data for ${var.name}"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-application"
    }
  )
}

resource "aws_kms_alias" "application" {
  name          = "alias/${var.name}-application"
  target_key_id = aws_kms_key.application.key_id
}

resource "random_password" "database" {
  length           = 32
  special          = true
  min_lower        = 4
  min_upper        = 4
  min_numeric      = 4
  min_special      = 4
  override_special = "!#$%&*()-_=+[]{}:,.?"
}

resource "aws_secretsmanager_secret" "database_credentials" {
  name                    = "${var.name}/database/credentials"
  description             = "Database credentials for ${var.name}"
  kms_key_id              = aws_kms_key.application.arn
  recovery_window_in_days = var.secret_recovery_window_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-database-credentials"
    }
  )
}

resource "aws_secretsmanager_secret_version" "database_credentials" {
  secret_id = aws_secretsmanager_secret.database_credentials.id

  secret_string = jsonencode(
    {
      username = var.database_username
      password = random_password.database.result
    }
  )
}

resource "random_password" "redis" {
  length  = 32
  special = true

  override_special = "!&#$^<>-"
}

resource "aws_secretsmanager_secret" "redis_credentials" {
  name                    = "${var.name}/redis/credentials"
  description             = "Redis authentication credentials for ${var.name}"
  kms_key_id              = aws_kms_key.application.arn
  recovery_window_in_days = var.secret_recovery_window_days

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "redis_credentials" {
  secret_id = aws_secretsmanager_secret.redis_credentials.id

  secret_string = jsonencode({
    auth_token = random_password.redis.result
  })
}