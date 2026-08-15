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