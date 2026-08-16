mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDATEST123456789"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::123456789012:root\"},\"Action\":\"kms:*\",\"Resource\":\"*\"}]}"
    }
  }
}

override_resource {
  target          = aws_kms_key.alerts
  override_during = plan

  values = {
    arn    = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
    key_id = "11111111-2222-3333-4444-555555555555"
  }
}

variables {
  name       = "test-platform-dev"
  aws_region = "us-east-1"

  alarm_email = null

  ecs_cluster_name = "test-platform-dev"
  ecs_service_name = "test-platform-dev-application"

  load_balancer_arn_suffix = "app/test-platform-dev/1234567890abcdef"
  target_group_arn_suffix  = "targetgroup/test-platform-dev/1234567890abcdef"

  rds_instance_id            = "test-platform-dev-postgres"
  redis_replication_group_id = "test-platform-dev-redis"

  ecs_cpu_threshold                 = 80
  ecs_memory_threshold              = 80
  rds_cpu_threshold                 = 80
  rds_free_storage_threshold_bytes  = 2147483648
  redis_cpu_threshold               = 80
  redis_free_memory_threshold_bytes = 52428800
  alb_5xx_threshold                 = 5
  alarm_evaluation_periods          = 2

  tags = {
    Environment = "test"
  }
}

run "monitoring_platform_plan" {
  command = plan

  assert {
    condition     = aws_kms_key.alerts.enable_key_rotation
    error_message = "The SNS alert KMS key must have rotation enabled."
  }

  assert {
    condition     = aws_kms_key.alerts.deletion_window_in_days == 7
    error_message = "The development alert key must use a seven-day deletion window."
  }

  assert {
    condition = (
      aws_sns_topic.alerts.kms_master_key_id ==
      aws_kms_key.alerts.arn
    )

    error_message = "The SNS alert topic must use the dedicated KMS key."
  }

  assert {
    condition     = length(aws_sns_topic_subscription.email) == 0
    error_message = "No email subscription must be created when alarm_email is null."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this) == 8
    error_message = "Eight infrastructure alarms must be created."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.this["ecs_high_cpu"].threshold ==
      80
    )

    error_message = "The ECS CPU alarm must use the configured threshold."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.this["rds_low_storage"].comparison_operator ==
      "LessThanOrEqualToThreshold"
    )

    error_message = "The RDS storage alarm must trigger when free storage is low."
  }

  assert {
    condition = (
      aws_cloudwatch_metric_alarm.this["alb_unhealthy_targets"]
      .dimensions["TargetGroup"] ==
      var.target_group_arn_suffix
    )

    error_message = "The unhealthy-target alarm must monitor the configured target group."
  }

  assert {
    condition = (
      length(
        jsondecode(
          aws_cloudwatch_dashboard.this.dashboard_body
        ).widgets
      ) == 5
    )

    error_message = "The operations dashboard must contain five widgets."
  }

  assert {
    condition     = length(output.alarm_names) == 8
    error_message = "Every alarm name must be exposed through the module output."
  }
}