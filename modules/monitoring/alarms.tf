locals {
  alarms = {
    ecs_high_cpu = {
      description         = "ECS service CPU utilization is too high."
      namespace           = "AWS/ECS"
      metric_name         = "CPUUtilization"
      statistic           = "Average"
      period              = 60
      threshold           = var.ecs_cpu_threshold
      comparison_operator = "GreaterThanOrEqualToThreshold"

      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }

    ecs_high_memory = {
      description         = "ECS service memory utilization is too high."
      namespace           = "AWS/ECS"
      metric_name         = "MemoryUtilization"
      statistic           = "Average"
      period              = 60
      threshold           = var.ecs_memory_threshold
      comparison_operator = "GreaterThanOrEqualToThreshold"

      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }

    alb_5xx_errors = {
      description         = "Application Load Balancer is returning HTTP 5xx errors."
      namespace           = "AWS/ApplicationELB"
      metric_name         = "HTTPCode_ELB_5XX_Count"
      statistic           = "Sum"
      period              = 60
      threshold           = var.alb_5xx_threshold
      comparison_operator = "GreaterThanOrEqualToThreshold"

      dimensions = {
        LoadBalancer = var.load_balancer_arn_suffix
      }
    }

    alb_unhealthy_targets = {
      description         = "Application Load Balancer has unhealthy ECS targets."
      namespace           = "AWS/ApplicationELB"
      metric_name         = "UnHealthyHostCount"
      statistic           = "Maximum"
      period              = 60
      threshold           = 1
      comparison_operator = "GreaterThanOrEqualToThreshold"

      dimensions = {
        LoadBalancer = var.load_balancer_arn_suffix
        TargetGroup  = var.target_group_arn_suffix
      }
    }

    rds_high_cpu = {
      description         = "RDS PostgreSQL CPU utilization is too high."
      namespace           = "AWS/RDS"
      metric_name         = "CPUUtilization"
      statistic           = "Average"
      period              = 60
      threshold           = var.rds_cpu_threshold
      comparison_operator = "GreaterThanOrEqualToThreshold"

      dimensions = {
        DBInstanceIdentifier = var.rds_instance_id
      }
    }

    rds_low_storage = {
      description         = "RDS PostgreSQL free storage is too low."
      namespace           = "AWS/RDS"
      metric_name         = "FreeStorageSpace"
      statistic           = "Average"
      period              = 60
      threshold           = var.rds_free_storage_threshold_bytes
      comparison_operator = "LessThanOrEqualToThreshold"

      dimensions = {
        DBInstanceIdentifier = var.rds_instance_id
      }
    }

    redis_high_cpu = {
      description         = "Redis engine CPU utilization is too high."
      namespace           = "AWS/ElastiCache"
      metric_name         = "EngineCPUUtilization"
      statistic           = "Average"
      period              = 60
      threshold           = var.redis_cpu_threshold
      comparison_operator = "GreaterThanOrEqualToThreshold"

      dimensions = {
        ReplicationGroupId = var.redis_replication_group_id
      }
    }

    redis_low_memory = {
      description         = "Redis free memory is too low."
      namespace           = "AWS/ElastiCache"
      metric_name         = "FreeableMemory"
      statistic           = "Average"
      period              = 60
      threshold           = var.redis_free_memory_threshold_bytes
      comparison_operator = "LessThanOrEqualToThreshold"

      dimensions = {
        ReplicationGroupId = var.redis_replication_group_id
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  for_each = local.alarms

  alarm_name        = "${var.name}-${replace(each.key, "_", "-")}"
  alarm_description = each.value.description

  namespace   = each.value.namespace
  metric_name = each.value.metric_name
  statistic   = each.value.statistic
  period      = each.value.period

  threshold           = each.value.threshold
  comparison_operator = each.value.comparison_operator

  evaluation_periods  = var.alarm_evaluation_periods
  datapoints_to_alarm = var.alarm_evaluation_periods

  dimensions = each.value.dimensions

  treat_missing_data = "notBreaching"

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions

  tags = local.common_tags
}