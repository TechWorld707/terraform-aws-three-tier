mock_provider "aws" {}

mock_provider "random" {}

variables {
  name     = "test-platform-dev"
  vpc_id   = "vpc-test123"
  vpc_cidr = "10.10.0.0/16"

  alb_ingress_cidrs = ["0.0.0.0/0"]
  alb_ingress_ports = [80, 443]

  application_port = 8080
  postgres_port    = 5432
  redis_port       = 6379

  database_username           = "app"
  kms_deletion_window_days    = 7
  secret_recovery_window_days = 0

  tags = {
    Environment = "test"
  }
}

run "security_foundation_plan" {
  command = plan

  assert {
    condition     = aws_security_group.alb.vpc_id == var.vpc_id
    error_message = "The ALB security group must be created in the supplied VPC."
  }

  assert {
    condition     = aws_security_group.ecs.vpc_id == var.vpc_id
    error_message = "The ECS security group must be created in the supplied VPC."
  }

  assert {
    condition     = aws_security_group.rds.vpc_id == var.vpc_id
    error_message = "The RDS security group must be created in the supplied VPC."
  }

  assert {
    condition     = aws_security_group.redis.vpc_id == var.vpc_id
    error_message = "The Redis security group must be created in the supplied VPC."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.alb) == 2
    error_message = "The ALB must expose HTTP and HTTPS."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.ecs_from_alb.from_port == 8080
    error_message = "ECS must accept traffic on the application port."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.rds_from_ecs.from_port == 5432
    error_message = "RDS must accept PostgreSQL traffic from ECS."
  }

  assert {
    condition     = aws_vpc_security_group_ingress_rule.redis_from_ecs.from_port == 6379
    error_message = "Redis must accept Redis traffic from ECS."
  }

  assert {
    condition     = aws_kms_key.application.enable_key_rotation == true
    error_message = "Application KMS key rotation must be enabled."
  }

  assert {
    condition     = aws_secretsmanager_secret.database_credentials.recovery_window_in_days == 0
    error_message = "The development test must support immediate secret deletion."
  }

  assert {
    condition     = random_password.database.length == 32
    error_message = "The generated database password must contain 32 characters."
  }
}