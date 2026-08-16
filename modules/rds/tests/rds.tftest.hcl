mock_provider "aws" {}

variables {
  name = "test-platform-dev"

  database_name     = "profiles"
  database_username = "app"
  database_password = "TestPassword-1234567890"

  database_subnet_ids = [
    "subnet-database-a",
    "subnet-database-b"
  ]

  security_group_id = "sg-rds123"
  kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"

  engine_version         = "17"
  parameter_group_family = "postgres17"
  instance_class         = "db.t4g.micro"

  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"

  multi_az              = false
  backup_retention_days = 1
  deletion_protection   = false
  skip_final_snapshot   = true
  apply_immediately     = true

  performance_insights_enabled = false
  monitoring_interval          = 0
  log_retention_days           = 30

  log_exports = [
    "postgresql",
    "upgrade"
  ]

  database_parameters = {
    log_min_duration_statement = "1000"
  }

  tags = {
    Environment = "test"
  }
}

run "development_rds_plan" {
  command = plan

  assert {
    condition     = aws_db_instance.this.engine == "postgres"
    error_message = "The database engine must be PostgreSQL."
  }

  assert {
    condition     = aws_db_instance.this.storage_encrypted
    error_message = "RDS storage encryption must be enabled."
  }

  assert {
    condition     = aws_db_instance.this.kms_key_id == var.kms_key_arn
    error_message = "RDS must use the configured KMS key."
  }

  assert {
    condition     = aws_db_instance.this.publicly_accessible == false
    error_message = "RDS must not be publicly accessible."
  }

  assert {
    condition     = length(aws_db_subnet_group.this.subnet_ids) == 2
    error_message = "The database subnet group must span at least two subnets."
  }

  assert {
    condition     = aws_db_instance.this.multi_az == false
    error_message = "The development database must use the cost-controlled Single-AZ configuration."
  }

  assert {
    condition     = aws_db_instance.this.backup_retention_period == 1
    error_message = "The development database must retain automated backups."
  }

  assert {
    condition     = aws_db_instance.this.iam_database_authentication_enabled
    error_message = "IAM database authentication must be enabled."
  }

  assert {
    condition     = aws_db_instance.this.skip_final_snapshot
    error_message = "The development database must support fast teardown without a final snapshot."
  }

  assert {
    condition     = aws_db_instance.this.deletion_protection == false
    error_message = "Development deletion protection must be disabled for controlled teardown."
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.rds) == 2
    error_message = "CloudWatch log groups must exist for PostgreSQL and upgrade logs."
  }

  assert {
    condition     = aws_db_parameter_group.this.family == "postgres17"
    error_message = "The parameter-group family must match PostgreSQL 17."
  }
}