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
    AWS_REGION = var.aws_region
  }

  # These will be populated after creating RDS, Redis and application S3.
  container_secrets = {}
  s3_bucket_arns    = []

  kms_key_arns = [
    module.security.application_kms_key_arn
  ]

  tags = local.common_tags
}