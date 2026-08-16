mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"backup.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}"
    }
  }
}

override_resource {
  target          = aws_backup_vault.this
  override_during = plan

  values = {
    arn  = "arn:aws:backup:us-east-1:123456789012:backup-vault:test-platform-dev-vault"
    id   = "test-platform-dev-vault"
    name = "test-platform-dev-vault"
  }
}

variables {
  name        = "test-platform-dev"
  kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"

  resource_arns = [
    "arn:aws:rds:us-east-1:123456789012:db:test-platform-dev-postgres",
    "arn:aws:s3:::test-platform-dev-submissions-a1b2c3d4"
  ]

  schedule_expression       = "cron(0 5 * * ? *)"
  start_window_minutes      = 60
  completion_window_minutes = 180
  delete_after_days         = 7

  enable_continuous_backup = false
  enable_vault_lock        = false

  vault_lock_min_retention_days = 7

  tags = {
    Environment = "test"
  }
}

run "development_backup_plan" {
  command = plan

  assert {
    condition     = aws_backup_vault.this.kms_key_arn == var.kms_key_arn
    error_message = "The backup vault must use the configured KMS key."
  }

  assert {
    condition = (
      one(
        aws_backup_plan.this.rule
      ).schedule == "cron(0 5 * * ? *)"
    )

    error_message = "The backup plan must use the configured daily schedule."
  }

  assert {
    condition = (
      one(
        one(
          aws_backup_plan.this.rule
        ).lifecycle
      ).delete_after == 7
    )

    error_message = "Development recovery points must expire after seven days."
  }

  assert {
    condition = (
      one(
        aws_backup_plan.this.rule
      ).enable_continuous_backup == false
    )

    error_message = "Development continuous backup must be disabled."
  }

  assert {
    condition     = length(aws_backup_selection.this.resources) == 2
    error_message = "The backup plan must protect the RDS instance and S3 archive bucket."
  }

  assert {
    condition     = length(aws_backup_vault_lock_configuration.this) == 0
    error_message = "Development Backup Vault Lock must be disabled for controlled teardown."
  }

  assert {
    condition = (
      aws_iam_role_policy_attachment.backup.policy_arn ==
      "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
    )

    error_message = "The backup role must have the AWS backup service policy."
  }

  assert {
    condition = (
      aws_iam_role_policy_attachment.restore.policy_arn ==
      "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
    )

    error_message = "The backup role must have the AWS restore service policy."
  }

  assert {
    condition     = output.vault_lock_enabled == false
    error_message = "The development output must report that Vault Lock is disabled."
  }
}