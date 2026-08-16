mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":[\"sts:AssumeRole\"],\"Principal\":{\"Service\":[\"ecs-tasks.amazonaws.com\"]}}]}"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }
}

override_resource {
  target          = aws_ecr_repository.application
  override_during = plan

  values = {
    arn            = "arn:aws:ecr:us-east-1:123456789012:repository/test-platform-dev"
    name           = "test-platform-dev"
    registry_id    = "123456789012"
    repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/test-platform-dev"
  }
}


variables {
  name = "test-platform-dev"

  vpc_id = "vpc-test123"

  public_subnet_ids = [
    "subnet-public-a",
    "subnet-public-b"
  ]

  private_subnet_ids = [
    "subnet-private-a",
    "subnet-private-b"
  ]

  alb_security_group_id = "sg-alb123"
  ecs_security_group_id = "sg-ecs123"

  container_port = 8080
  image_tag      = "bootstrap"
  desired_count  = 0

  task_cpu    = 256
  task_memory = 512

  health_check_path      = "/health"
  log_retention_days     = 30
  ecr_force_delete       = false
  ecr_kms_key_arn        = null
  enable_execute_command = true

  container_environment = {
    AWS_REGION = "us-east-1"
  }

  container_secrets = {
    DATABASE_URL = "arn:aws:secretsmanager:us-east-1:123456789012:secret:test-platform-dev/application/runtime-AbCdEf:DATABASE_URL::"
    REDIS_URL    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:test-platform-dev/application/runtime-AbCdEf:REDIS_URL::"
  }

  kms_key_arns   = []
  s3_bucket_arns = []

  tags = {
    Environment = "test"
  }
}

run "ecs_platform_plan" {
  command = plan

  assert {
    condition     = aws_ecr_repository.application.image_tag_mutability == "IMMUTABLE"
    error_message = "ECR image tags must be immutable."
  }

  assert {
    condition     = aws_ecr_repository.application.image_scanning_configuration[0].scan_on_push
    error_message = "ECR images must be scanned when pushed."
  }

  assert {
    condition     = aws_lb.application.internal == false
    error_message = "The Application Load Balancer must be internet-facing."
  }

  assert {
    condition     = aws_lb_target_group.application.target_type == "ip"
    error_message = "The target group must use IP targets for Fargate."
  }

  assert {
    condition     = aws_lb_target_group.application.port == 8080
    error_message = "The target group must use the configured application port."
  }

  assert {
    condition     = aws_ecs_task_definition.application.network_mode == "awsvpc"
    error_message = "The Fargate task must use awsvpc networking."
  }

  assert {
    condition = contains(
      aws_ecs_task_definition.application.requires_compatibilities,
      "FARGATE"
    )
    error_message = "The task definition must support Fargate."
  }

  assert {
    condition = (
      jsondecode(
        aws_ecs_task_definition.application.container_definitions
      )[0].user == "10001"
    )
    error_message = "The application container must run as a non-root user."
  }

  assert {
    condition = (
      jsondecode(
        aws_ecs_task_definition.application.container_definitions
      )[0].readonlyRootFilesystem == true
    )
    error_message = "The application container must have a read-only root filesystem."
  }

  assert {
    condition     = aws_ecs_service.application.desired_count == 0
    error_message = "The bootstrap ECS service must initially run zero tasks."
  }

  assert {
    condition = (
      aws_ecs_service.application.network_configuration[0].assign_public_ip ==
      false
    )
    error_message = "ECS tasks in private subnets must not receive public IP addresses."
  }

  assert {
    condition = (
      aws_ecs_service.application.deployment_circuit_breaker[0].enable &&
      aws_ecs_service.application.deployment_circuit_breaker[0].rollback
    )
    error_message = "The ECS deployment circuit breaker and rollback must be enabled."
  }

  assert {
    condition     = aws_ecs_service.application.enable_execute_command
    error_message = "ECS Exec must be enabled for controlled troubleshooting."
  }

  assert {
    condition     = aws_cloudwatch_log_group.application.retention_in_days == 30
    error_message = "Application logs must use the configured retention period."
  }
}