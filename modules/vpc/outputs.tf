output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block assigned to the VPC."
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the VPC internet gateway."
  value       = aws_internet_gateway.this.id
}

output "availability_zones" {
  description = "Availability Zones used by the VPC."
  value       = var.availability_zones
}

output "public_subnet_ids" {
  description = "IDs of the public subnets in Availability Zone order."
  value = [
    for key in sort(keys(aws_subnet.public)) :
    aws_subnet.public[key].id
  ]
}

output "private_application_subnet_ids" {
  description = "IDs of the private application subnets in Availability Zone order."
  value = [
    for key in sort(keys(aws_subnet.private_application)) :
    aws_subnet.private_application[key].id
  ]
}

output "isolated_database_subnet_ids" {
  description = "IDs of the isolated database subnets in Availability Zone order."
  value = [
    for key in sort(keys(aws_subnet.isolated_database)) :
    aws_subnet.isolated_database[key].id
  ]
}

output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_application_route_table_ids" {
  description = "IDs of the private application route tables."
  value = [
    for key in sort(keys(aws_route_table.private_application)) :
    aws_route_table.private_application[key].id
  ]
}

output "isolated_database_route_table_ids" {
  description = "IDs of the isolated database route tables."
  value = [
    for key in sort(keys(aws_route_table.isolated_database)) :
    aws_route_table.isolated_database[key].id
  ]
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways."
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_public_ips" {
  description = "Public IP addresses assigned to the NAT gateways."
  value       = aws_eip.nat[*].public_ip
}


output "flow_log_id" {
  description = "ID of the VPC Flow Log, or null when disabled."
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_group_name" {
  description = "CloudWatch log group receiving VPC Flow Logs, or null when disabled."
  value       = try(aws_cloudwatch_log_group.vpc_flow_logs[0].name, null)
}