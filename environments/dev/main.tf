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