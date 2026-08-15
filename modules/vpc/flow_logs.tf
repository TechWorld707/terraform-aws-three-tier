resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.name}/flow-logs"
  retention_in_days = var.flow_log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-vpc-flow-logs"
    }
  )
}

data "aws_iam_policy_document" "vpc_flow_logs_assume" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name               = "${var.name}-vpc-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_logs_assume[0].json

  tags = local.common_tags
}

data "aws_iam_policy_document" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]

    resources = [
      "${aws_cloudwatch_log_group.vpc_flow_logs[0].arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_flow_logs ? 1 : 0

  name   = "${var.name}-vpc-flow-logs"
  role   = aws_iam_role.vpc_flow_logs[0].id
  policy = data.aws_iam_policy_document.vpc_flow_logs[0].json
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  vpc_id                   = aws_vpc.this.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  iam_role_arn             = aws_iam_role.vpc_flow_logs[0].arn
  max_aggregation_interval = 60

  log_format = join(
    " ",
    [
      "$${version}",
      "$${account-id}",
      "$${interface-id}",
      "$${srcaddr}",
      "$${dstaddr}",
      "$${srcport}",
      "$${dstport}",
      "$${protocol}",
      "$${packets}",
      "$${bytes}",
      "$${start}",
      "$${end}",
      "$${action}",
      "$${log-status}",
      "$${vpc-id}",
      "$${subnet-id}",
      "$${instance-id}",
      "$${flow-direction}",
      "$${traffic-path}",
    ]
  )

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-vpc-flow-log"
    }
  )

  depends_on = [aws_iam_role_policy.vpc_flow_logs]
}