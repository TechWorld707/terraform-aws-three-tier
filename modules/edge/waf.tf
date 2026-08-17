locals {
  managed_rule_groups = {
    common = {
      priority = 20
      name     = "AWSManagedRulesCommonRuleSet"
    }

    ip_reputation = {
      priority = 40
      name     = "AWSManagedRulesAmazonIpReputationList"
    }
  }
}

resource "aws_wafv2_web_acl" "cloudfront" {
  name        = "${var.name}-cloudfront"
  description = "CloudFront protection for ${var.name}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "rate-limit"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-rate-limit"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "known-bad-inputs"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.name}-known-bad-inputs"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = local.managed_rule_groups

    content {
      name     = rule.key
      priority = rule.value.priority

      override_action {
        none {}
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = "AWS"
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "${var.name}-${rule.key}"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.name}-cloudfront"
    sampled_requests_enabled   = true
  }

  tags = local.common_tags
}


resource "aws_cloudwatch_log_group" "waf" {
  #checkov:skip=CKV_AWS_338:WAF log retention is configurable by environment to balance security visibility and development cost.
  name              = "aws-waf-logs-${var.name}-cloudfront"
  retention_in_days = var.waf_log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = local.common_tags
}

resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  resource_arn = aws_wafv2_web_acl.cloudfront.arn

  log_destination_configs = [
    aws_cloudwatch_log_group.waf.arn
  ]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}

