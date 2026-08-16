locals {
  managed_rule_groups = {
    common = {
      priority = 20
      name     = "AWSManagedRulesCommonRuleSet"
    }

    known_bad_inputs = {
      priority = 30
      name     = "AWSManagedRulesKnownBadInputsRuleSet"
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