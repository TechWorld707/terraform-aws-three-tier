mock_provider "aws" {}

variables {
  name = "test-platform-dev"

  subnet_ids = [
    "subnet-private-a",
    "subnet-private-b"
  ]

  security_group_id = "sg-redis123"
  kms_key_arn       = "arn:aws:kms:us-east-1:123456789012:key/11111111-2222-3333-4444-555555555555"
  auth_token        = "TestRedisToken-123456789"

  engine_version         = "7.1"
  parameter_group_family = "redis7"
  node_type              = "cache.t4g.micro"

  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false

  snapshot_retention_limit   = 0
  apply_immediately          = true
  auto_minor_version_upgrade = true
  log_retention_days         = 30

  tags = {
    Environment = "test"
  }
}

run "development_redis_plan" {
  command = plan

  assert {
    condition     = aws_elasticache_replication_group.this.engine == "redis"
    error_message = "The ElastiCache engine must be Redis."
  }

  assert {
    condition     = aws_elasticache_replication_group.this.engine_version == "7.1"
    error_message = "The configured Redis engine version must be used."
  }

  assert {
    condition     = aws_elasticache_replication_group.this.at_rest_encryption_enabled
    error_message = "Redis encryption at rest must be enabled."
  }

  assert {
    condition     = aws_elasticache_replication_group.this.kms_key_id == var.kms_key_arn
    error_message = "Redis must use the configured KMS key."
  }

  assert {
    condition     = aws_elasticache_replication_group.this.transit_encryption_enabled
    error_message = "Redis encryption in transit must be enabled."
  }

  assert {
    condition     = aws_elasticache_replication_group.this.transit_encryption_mode == "required"
    error_message = "Encrypted Redis connections must be required."
  }

  assert {
    condition     = length(aws_elasticache_subnet_group.this.subnet_ids) == 2
    error_message = "The Redis subnet group must span at least two subnets."
  }

  assert {
    condition     = aws_elasticache_replication_group.this.num_cache_clusters == 1
    error_message = "Development must use one Redis node for cost control."
  }

  assert {
    condition     = aws_elasticache_replication_group.this.automatic_failover_enabled == false
    error_message = "Development automatic failover must be disabled."
  }

  assert {
    condition     = aws_elasticache_replication_group.this.multi_az_enabled == false
    error_message = "Development Multi-AZ Redis must be disabled."
  }

  assert {
    condition     = aws_elasticache_replication_group.this.snapshot_retention_limit == 0
    error_message = "Development Redis snapshots must be disabled for fast teardown."
  }

  assert {
    condition     = length(aws_cloudwatch_log_group.redis) == 2
    error_message = "Redis engine and slow-log CloudWatch groups must be created."
  }

  assert {
    condition     = aws_elasticache_parameter_group.this.family == "redis7"
    error_message = "The parameter-group family must match Redis 7."
  }
}