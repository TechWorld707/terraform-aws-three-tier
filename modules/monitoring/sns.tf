data "aws_iam_policy_document" "alerts_kms" {
  #checkov:skip=CKV_AWS_109:KMS key administration is restricted to this AWS account root principal.
  #checkov:skip=CKV_AWS_111:KMS key administration requires write actions and is restricted to this AWS account root principal.
  #checkov:skip=CKV_AWS_356:KMS key policies use Resource "*" to represent only the key to which the policy is attached.

  statement {
    sid    = "EnableAccountAdministration"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:*"
    ]

    resources = ["*"]
  }
  statement {
    sid    = "AllowCloudWatchAndSNS"
    effect = "Allow"

    principals {
      type = "Service"

      identifiers = [
        "cloudwatch.amazonaws.com",
        "sns.amazonaws.com"
      ]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }
}

resource "aws_kms_key" "alerts" {
  description             = "SNS alarm encryption key for ${var.name}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.alerts_kms.json

  tags = local.common_tags
}

resource "aws_kms_alias" "alerts" {
  name          = "alias/${var.name}-alerts"
  target_key_id = aws_kms_key.alerts.key_id
}

resource "aws_sns_topic" "alerts" {
  name              = "${var.name}-alerts"
  kms_master_key_id = aws_kms_key.alerts.arn

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "email" {
  count = nonsensitive(var.alarm_email != null) ? 1 : 0

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
