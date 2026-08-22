locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Module    = "ecs"
    }
  )

  container_secret_arns = toset([
    for secret_reference in values(var.container_secrets) :
    replace(secret_reference, "/:[^:]+::$/", "")
  ])
}

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT"
  ]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

resource "aws_ecs_service" "application" {
  name            = "${var.name}-application"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.application.arn
  desired_count   = var.desired_count

  enable_execute_command            = var.enable_execute_command
  health_check_grace_period_seconds = 60
  wait_for_steady_state             = false

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.application.arn
    container_name   = "application"
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.http
  ]

  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition
    ]
  }

  tags = local.common_tags
}