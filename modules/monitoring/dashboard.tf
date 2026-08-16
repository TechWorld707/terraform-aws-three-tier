resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name}-operations"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2

        properties = {
          markdown = "# ${var.name} operations dashboard\nRegion: `${var.aws_region}`"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6

        properties = {
          title  = "ECS service utilization"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName",
              var.ecs_cluster_name,
              "ServiceName",
              var.ecs_service_name,
              {
                label = "CPU utilization"
              }
            ],
            [
              "AWS/ECS",
              "MemoryUtilization",
              "ClusterName",
              var.ecs_cluster_name,
              "ServiceName",
              var.ecs_service_name,
              {
                label = "Memory utilization"
              }
            ]
          ]

          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6

        properties = {
          title  = "Application Load Balancer"
          region = var.aws_region
          view   = "timeSeries"
          period = 60

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              {
                stat  = "Sum"
                label = "Requests"
              }
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              {
                stat  = "Sum"
                label = "ALB 5xx"
              }
            ],
            [
              "AWS/ApplicationELB",
              "UnHealthyHostCount",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              "TargetGroup",
              var.target_group_arn_suffix,
              {
                stat  = "Maximum"
                label = "Unhealthy targets"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6

        properties = {
          title  = "RDS PostgreSQL"
          region = var.aws_region
          view   = "timeSeries"
          period = 60

          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              var.rds_instance_id,
              {
                stat  = "Average"
                label = "CPU utilization"
              }
            ],
            [
              "AWS/RDS",
              "DatabaseConnections",
              "DBInstanceIdentifier",
              var.rds_instance_id,
              {
                stat  = "Average"
                label = "Connections"
              }
            ],
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier",
              var.rds_instance_id,
              {
                stat  = "Average"
                label = "Free storage"
              }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6

        properties = {
          title  = "ElastiCache Redis"
          region = var.aws_region
          view   = "timeSeries"
          period = 60

          metrics = [
            [
              "AWS/ElastiCache",
              "EngineCPUUtilization",
              "ReplicationGroupId",
              var.redis_replication_group_id,
              {
                stat  = "Average"
                label = "Engine CPU"
              }
            ],
            [
              "AWS/ElastiCache",
              "FreeableMemory",
              "ReplicationGroupId",
              var.redis_replication_group_id,
              {
                stat  = "Average"
                label = "Free memory"
              }
            ],
            [
              "AWS/ElastiCache",
              "CurrConnections",
              "ReplicationGroupId",
              var.redis_replication_group_id,
              {
                stat  = "Average"
                label = "Connections"
              }
            ]
          ]
        }
      }
    ]
  })
}