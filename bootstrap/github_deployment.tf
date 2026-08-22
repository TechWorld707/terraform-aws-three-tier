data "aws_iam_policy_document" "github_application_deployment" {
  #checkov:skip=CKV_AWS_356:ECR authentication and ECS task-definition registration and inspection require wildcard resources because these actions cannot be reliably scoped to deployment-time resource ARNs.
  for_each = var.environments

  statement {
    sid    = "AuthenticateToECR"
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "PushApplicationImage"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-${each.key}"
    ]
  }

  statement {
    sid    = "ReadAndUpdateECSService"
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.project_name}-${each.key}/${var.project_name}-${each.key}-application"
    ]
  }

  statement {
    sid    = "DescribeTaskDefinitions"
    effect = "Allow"

    actions = [
      "ecs:DescribeTaskDefinition"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "RegisterTaskDefinitionRevision"
    effect = "Allow"

    actions = [
      "ecs:RegisterTaskDefinition"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "RunDatabaseMigrationTask"
    effect = "Allow"

    actions = [
      "ecs:RunTask"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${var.project_name}-${each.key}-application:*"
    ]

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"

      values = [
        "arn:${data.aws_partition.current.partition}:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.project_name}-${each.key}"
      ]
    }
  }

  statement {
    sid    = "DescribeDatabaseMigrationTasks"
    effect = "Allow"

    actions = [
      "ecs:DescribeTasks"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "PassECSTaskRoles"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${each.key}-task",
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/${var.project_name}-${each.key}-task-execution"
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"

      values = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "github_application_deployment" {
  for_each = var.environments

  name = "${var.project_name}-github-${each.key}-application-deployment"

  description = "Allows GitHub Actions to push application images and deploy the ${each.key} ECS service."

  policy = data.aws_iam_policy_document.github_application_deployment[each.key].json

  tags = {
    Environment = each.key
  }
}

resource "aws_iam_role_policy_attachment" "github_application_deployment" {
  for_each = var.environments

  role       = aws_iam_role.github_environment[each.key].name
  policy_arn = aws_iam_policy.github_application_deployment[each.key].arn
}