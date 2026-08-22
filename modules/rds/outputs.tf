output "db_instance_id" {
  description = "RDS database instance identifier."
  value       = aws_db_instance.this.identifier
}

output "db_instance_arn" {
  description = "ARN of the RDS database instance."
  value       = aws_db_instance.this.arn
}

output "db_instance_address" {
  description = "Private DNS address of the RDS database."
  value       = aws_db_instance.this.address
}

output "db_instance_endpoint" {
  description = "RDS connection endpoint including the port."
  value       = aws_db_instance.this.endpoint
}

output "db_instance_port" {
  description = "PostgreSQL listener port."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Name of the PostgreSQL application database."
  value       = aws_db_instance.this.db_name
}

output "db_subnet_group_name" {
  description = "Name of the RDS database subnet group."
  value       = aws_db_subnet_group.this.name
}

output "db_parameter_group_name" {
  description = "Name of the custom PostgreSQL parameter group."
  value       = aws_db_parameter_group.this.name
}

output "cloudwatch_log_group_names" {
  description = "CloudWatch log groups receiving PostgreSQL logs."
  value = {
    for log_type, log_group in aws_cloudwatch_log_group.rds :
    log_type => log_group.name
  }
}

output "enhanced_monitoring_role_arn" {
  description = "ARN of the enhanced-monitoring IAM role, when enabled."
  value = (
    var.monitoring_interval > 0
    ? aws_iam_role.enhanced_monitoring[0].arn
    : null
  )
}