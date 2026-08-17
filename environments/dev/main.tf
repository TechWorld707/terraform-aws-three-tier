data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  common_tags = merge(
    var.tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )

  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    var.availability_zone_count
  )

  public_subnet_cidrs = [
    for index in range(var.availability_zone_count) :
    cidrsubnet(var.vpc_cidr, 8, index)
  ]

  private_application_subnet_cidrs = [
    for index in range(var.availability_zone_count) :
    cidrsubnet(var.vpc_cidr, 8, index + 10)
  ]

  isolated_database_subnet_cidrs = [
    for index in range(var.availability_zone_count) :
    cidrsubnet(var.vpc_cidr, 8, index + 20)
  ]
}

module "vpc" {
  source = "../../modules/vpc"

  name                             = "${var.project_name}-${var.environment}"
  vpc_cidr                         = var.vpc_cidr
  availability_zones               = local.availability_zones
  public_subnet_cidrs              = local.public_subnet_cidrs
  private_application_subnet_cidrs = local.private_application_subnet_cidrs
  isolated_database_subnet_cidrs   = local.isolated_database_subnet_cidrs
  enable_nat_gateway               = var.enable_nat_gateway
  single_nat_gateway               = var.single_nat_gateway
  enable_flow_logs                 = var.enable_flow_logs
  flow_log_retention_days          = var.flow_log_retention_days
  tags                             = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name     = "${var.project_name}-${var.environment}"
  vpc_id   = module.vpc.vpc_id
  vpc_cidr = module.vpc.vpc_cidr_block

  application_port = 8080
  postgres_port    = 5432
  redis_port       = 6379

  database_username           = var.database_username
  kms_deletion_window_days    = var.kms_deletion_window_days
  secret_recovery_window_days = var.secret_recovery_window_days

  tags = local.common_tags
}
module "ecs" {
  source = "../../modules/ecs"

  name   = "${var.project_name}-${var.environment}"
  vpc_id = module.vpc.vpc_id

  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_application_subnet_ids

  alb_security_group_id = module.security.alb_security_group_id
  ecs_security_group_id = module.security.ecs_security_group_id

  container_port = 8080
  image_tag      = var.container_image_tag
  desired_count  = var.ecs_desired_count

  task_cpu    = 256
  task_memory = 512

  health_check_path      = "/health"
  log_retention_days     = 30
  enable_execute_command = true

  ecr_force_delete = var.ecr_force_delete
  ecr_kms_key_arn  = module.security.application_kms_key_arn


  container_environment = {
    AWS_REGION     = var.aws_region
    S3_BUCKET      = module.storage.bucket_name
    S3_KMS_KEY_ARN = module.security.application_kms_key_arn
  }

  container_secrets = module.runtime.ecs_container_secrets

  kms_key_arns = [
    module.security.application_kms_key_arn
  ]

  s3_bucket_arns = [
    module.storage.bucket_arn
  ]

  tags = local.common_tags
}

module "edge" {
  source = "../../modules/edge"

  name            = "${var.project_name}-${var.environment}"
  alb_domain_name = module.ecs.load_balancer_dns_name
  kms_key_arn     = module.security.application_kms_key_arn

  frontend_source_directory = "${path.root}/../../frontend"
  frontend_force_destroy    = true

  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  enable_ipv6         = true
  waf_rate_limit      = 1000

  # CloudFront supplies a generated HTTPS hostname until a domain is added.
  domain_name         = null
  acm_certificate_arn = null

  tags = local.common_tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  name        = "${var.project_name}-${var.environment}"
  aws_region  = var.aws_region
  alarm_email = var.alarm_email

  ecs_cluster_name = module.ecs.ecs_cluster_name
  ecs_service_name = module.ecs.ecs_service_name

  load_balancer_arn_suffix = module.ecs.load_balancer_arn_suffix
  target_group_arn_suffix  = module.ecs.target_group_arn_suffix

  rds_instance_id            = module.rds.db_instance_id
  redis_replication_group_id = module.redis.replication_group_id

  ecs_cpu_threshold    = 80
  ecs_memory_threshold = 80

  rds_cpu_threshold                = 80
  rds_free_storage_threshold_bytes = 2147483648

  redis_cpu_threshold               = 80
  redis_free_memory_threshold_bytes = 52428800

  alb_5xx_threshold        = 5
  alarm_evaluation_periods = 2

  tags = local.common_tags
}

module "backup" {
  source = "../../modules/backup"

  name        = "${var.project_name}-${var.environment}"
  kms_key_arn = module.security.application_kms_key_arn

  resource_arns = [
    module.rds.db_instance_arn,
    module.storage.bucket_arn
  ]

  schedule_expression       = "cron(0 5 * * ? *)"
  start_window_minutes      = 60
  completion_window_minutes = 180
  delete_after_days         = 7

  enable_continuous_backup = false
  enable_vault_lock        = false

  vault_lock_min_retention_days = 7

  tags = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name = "${var.project_name}-${var.environment}-postgres"

  database_name     = "profiles"
  database_username = module.security.database_username
  database_password = module.security.database_password

  database_subnet_ids = module.vpc.isolated_database_subnet_ids
  security_group_id   = module.security.rds_security_group_id
  kms_key_arn         = module.security.application_kms_key_arn

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

  tags = local.common_tags
}

module "redis" {
  source = "../../modules/redis"

  name = "${var.project_name}-${var.environment}-redis"

  subnet_ids        = module.vpc.isolated_database_subnet_ids
  security_group_id = module.security.redis_security_group_id
  kms_key_arn       = module.security.application_kms_key_arn
  auth_token        = module.security.redis_auth_token

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

  tags = local.common_tags
}

module "storage" {
  source = "../../modules/storage"

  name        = "${var.project_name}-${var.environment}"
  kms_key_arn = module.security.application_kms_key_arn

  # Development resources must support controlled teardown.
  force_destroy      = true
  versioning_enabled = true

  object_expiration_days                 = 90
  noncurrent_version_expiration_days     = 30
  abort_incomplete_multipart_upload_days = 7

  tags = local.common_tags
}

module "runtime" {
  source = "../../modules/runtime"

  name        = "${var.project_name}-${var.environment}"
  kms_key_arn = module.security.application_kms_key_arn

  secret_recovery_window_days = 0

  database_host     = module.rds.db_instance_address
  database_port     = module.rds.db_instance_port
  database_name     = module.rds.database_name
  database_username = module.security.database_username
  database_password = module.security.database_password

  redis_host       = module.redis.primary_endpoint_address
  redis_port       = module.redis.port
  redis_auth_token = module.security.redis_auth_token

  s3_bucket_name = module.storage.bucket_name
  aws_region     = var.aws_region

  tags = local.common_tags
}