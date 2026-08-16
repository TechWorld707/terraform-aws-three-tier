mock_provider "aws" {}

override_resource {
  target          = aws_secretsmanager_secret.runtime
  override_during = plan

  values = {
    arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:test-platform-dev/application/runtime-AbCdEf"
    id   = "arn:aws:secretsmanager:us-east-1:123456789012:secret:test-platform-dev/application/runtime-AbCdEf"
    name = "test-platform-dev/application/runtime"
  }
}

variables {
  name        = "test-platform-dev"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"

  secret_recovery_window_days = 0

  database_host     = "database.test.internal"
  database_port     = 5432
  database_name     = "profiles"
  database_username = "app"
  database_password = "Test#Password&123456"

  redis_host       = "redis.test.internal"
  redis_port       = 6379
  redis_auth_token = "TestRedis#Token&123456"

  s3_bucket_name = "test-platform-dev-submissions-a1b2c3d4"
  aws_region     = "us-east-1"

  tags = {
    Environment = "test"
  }
}

run "runtime_configuration_plan" {
  command = plan

  assert {
    condition = (
      aws_secretsmanager_secret.runtime.kms_key_id ==
      var.kms_key_arn
    )

    error_message = "The runtime secret must use the application KMS key."
  }

  assert {
    condition = (
      aws_secretsmanager_secret.runtime.recovery_window_in_days == 0
    )

    error_message = "The development runtime secret must support immediate teardown."
  }

  assert {
    condition = startswith(
      jsondecode(
        aws_secretsmanager_secret_version.runtime.secret_string
      ).DATABASE_URL,
      "postgresql+psycopg://"
    )

    error_message = "DATABASE_URL must use the PostgreSQL psycopg driver."
  }

  assert {
    condition = strcontains(
      jsondecode(
        aws_secretsmanager_secret_version.runtime.secret_string
      ).DATABASE_URL,
      "sslmode=require"
    )

    error_message = "The PostgreSQL connection must require TLS."
  }

  assert {
    condition = strcontains(
      jsondecode(
        aws_secretsmanager_secret_version.runtime.secret_string
      ).DATABASE_URL,
      "%23"
    )

    error_message = "Special database-password characters must be URL encoded."
  }

  assert {
    condition = startswith(
      jsondecode(
        aws_secretsmanager_secret_version.runtime.secret_string
      ).REDIS_URL,
      "rediss://"
    )

    error_message = "REDIS_URL must require TLS."
  }

  assert {
    condition = strcontains(
      jsondecode(
        aws_secretsmanager_secret_version.runtime.secret_string
      ).REDIS_URL,
      "%23"
    )

    error_message = "Special Redis-token characters must be URL encoded."
  }

  assert {
    condition = (
      output.ecs_container_secrets.DATABASE_URL ==
      "${aws_secretsmanager_secret.runtime.arn}:DATABASE_URL::"
    )

    error_message = "The ECS database secret reference must select DATABASE_URL."
  }

  assert {
    condition = (
      output.ecs_container_secrets.REDIS_URL ==
      "${aws_secretsmanager_secret.runtime.arn}:REDIS_URL::"
    )

    error_message = "The ECS Redis secret reference must select REDIS_URL."
  }
}