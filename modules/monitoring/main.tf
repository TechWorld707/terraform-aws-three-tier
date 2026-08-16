locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "monitoring"
    }
  )

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]
}

data "aws_caller_identity" "current" {}