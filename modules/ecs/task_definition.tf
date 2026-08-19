data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/ecs/${var.name}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_arn

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "application" {
  family                   = "${var.name}-application"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = tostring(var.task_cpu)
  memory = tostring(var.task_memory)

  execution_role_arn = aws_iam_role.task_execution.arn
  task_role_arn      = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  volume {
    name = "application-tmp"
  }

  container_definitions = jsonencode([
    {
      name      = "application"
      image     = "${aws_ecr_repository.application.repository_url}:${var.image_tag}"
      essential = true

      # Run the container as a non-root Linux user.
      user = "10001"

      portMappings = [
        {
          name          = "application"
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "application-tmp"
          containerPath = "/tmp"
          readOnly      = false
        }
      ]

      environment = [
        for key in sort(keys(var.container_environment)) : {
          name  = key
          value = var.container_environment[key]
        }
      ]

      secrets = [
        for key in sort(keys(var.container_secrets)) : {
          name      = key
          valueFrom = var.container_secrets[key]
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.application.name
          awslogs-region        = data.aws_region.current.region
          awslogs-stream-prefix = "application"
        }
      }

      healthCheck = {
        command = [
          "CMD-SHELL",
          "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:${var.container_port}${var.health_check_path}', timeout=2)\" || exit 1"
        ]

        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }

      readonlyRootFilesystem = true

      linuxParameters = {
        initProcessEnabled = true
      }
    }
  ])

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}