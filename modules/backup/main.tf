locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "backup"
    }
  )
}

data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "backup.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "${var.name}-backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_vault" "this" {
  name        = "${var.name}-vault"
  kms_key_arn = var.kms_key_arn

  tags = local.common_tags
}

resource "aws_backup_plan" "this" {
  name = "${var.name}-plan"

  rule {
    rule_name         = "${var.name}-daily"
    target_vault_name = aws_backup_vault.this.name
    schedule          = var.schedule_expression

    start_window      = var.start_window_minutes
    completion_window = var.completion_window_minutes

    enable_continuous_backup = var.enable_continuous_backup

    lifecycle {
      delete_after = var.delete_after_days
    }

    recovery_point_tags = local.common_tags
  }

  tags = local.common_tags
}

resource "aws_backup_selection" "this" {
  name         = "${var.name}-resources"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.this.id

  resources = var.resource_arns
}

resource "aws_backup_vault_lock_configuration" "this" {
  count = var.enable_vault_lock ? 1 : 0

  backup_vault_name  = aws_backup_vault.this.name
  min_retention_days = var.vault_lock_min_retention_days
}