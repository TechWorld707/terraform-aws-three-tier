output "vpc_id" {
  description = "ID of the development VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block assigned to the development VPC."
  value       = module.vpc.vpc_cidr_block
}

output "availability_zones" {
  description = "Availability Zones used by development."
  value       = module.vpc.availability_zones
}

output "public_subnet_ids" {
  description = "Public subnet IDs for the load balancer and NAT gateway."
  value       = module.vpc.public_subnet_ids
}

output "private_application_subnet_ids" {
  description = "Private subnet IDs for ECS Fargate."
  value       = module.vpc.private_application_subnet_ids
}

output "isolated_database_subnet_ids" {
  description = "Isolated subnet IDs for RDS and ElastiCache."
  value       = module.vpc.isolated_database_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT gateway IDs created for development."
  value       = module.vpc.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "Public IP addresses assigned to development NAT gateways."
  value       = module.vpc.nat_gateway_public_ips
}

output "flow_log_id" {
  description = "ID of the development VPC Flow Log."
  value       = module.vpc.flow_log_id
}

output "flow_log_group_name" {
  description = "CloudWatch log group receiving development VPC Flow Logs."
  value       = module.vpc.flow_log_group_name
}

output "alb_security_group_id" {
  description = "Security group ID assigned to the development ALB."
  value       = module.security.alb_security_group_id
}

output "ecs_security_group_id" {
  description = "Security group ID assigned to development ECS tasks."
  value       = module.security.ecs_security_group_id
}

output "rds_security_group_id" {
  description = "Security group ID assigned to development RDS."
  value       = module.security.rds_security_group_id
}

output "redis_security_group_id" {
  description = "Security group ID assigned to development Redis."
  value       = module.security.redis_security_group_id
}

output "application_kms_key_arn" {
  description = "ARN of the development application KMS key."
  value       = module.security.application_kms_key_arn
}

output "database_credentials_secret_arn" {
  description = "ARN of the development database credentials secret."
  value       = module.security.database_credentials_secret_arn
}