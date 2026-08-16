data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name}-task-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${var.name}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "task_execution_secrets" {
  count = length(var.container_secrets) > 0 ? 1 : 0

  statement {
    sid    = "ReadApplicationSecrets"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = local.container_secret_arns
  }
}

resource "aws_iam_role_policy" "task_execution_secrets" {
  count = length(var.container_secrets) > 0 ? 1 : 0

  name   = "${var.name}-read-secrets"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.task_execution_secrets[0].json
}

data "aws_iam_policy_document" "task_execution_kms" {
  count = length(var.kms_key_arns) > 0 ? 1 : 0

  statement {
    sid    = "DecryptApplicationSecrets"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = var.kms_key_arns
  }
}

resource "aws_iam_role_policy" "task_execution_kms" {
  count = length(var.kms_key_arns) > 0 ? 1 : 0

  name   = "${var.name}-decrypt-secrets"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.task_execution_kms[0].json
}

data "aws_iam_policy_document" "task_s3" {
  count = length(var.s3_bucket_arns) > 0 ? 1 : 0

  statement {
    sid    = "ListSubmissionBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = var.s3_bucket_arns
  }

  statement {
    sid    = "ReadWriteSubmissionObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      for bucket_arn in var.s3_bucket_arns : "${bucket_arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "task_s3" {
  count = length(var.s3_bucket_arns) > 0 ? 1 : 0

  name   = "${var.name}-submission-storage"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_s3[0].json
}

data "aws_iam_policy_document" "task_kms" {
  count = length(var.kms_key_arns) > 0 ? 1 : 0

  statement {
    sid    = "UseApplicationEncryptionKey"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = var.kms_key_arns
  }
}

resource "aws_iam_role_policy" "task_kms" {
  count = length(var.kms_key_arns) > 0 ? 1 : 0

  name   = "${var.name}-application-encryption"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_kms[0].json
}