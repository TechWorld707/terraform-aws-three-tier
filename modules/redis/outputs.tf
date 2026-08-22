output "replication_group_id" {
  description = "ID of the Redis replication group."
  value       = aws_elasticache_replication_group.this.id
}

output "replication_group_arn" {
  description = "ARN of the Redis replication group."
  value       = aws_elasticache_replication_group.this.arn
}

output "primary_cache_cluster_id" {
  description = "ID of the primary Redis cache cluster used for node-level CloudWatch metrics."
  value = sort(
    tolist(aws_elasticache_replication_group.this.member_clusters)
  )[0]
}

output "primary_endpoint_address" {
  description = "Private primary endpoint used for Redis writes."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Private reader endpoint when replica nodes exist."
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  description = "Redis listener port."
  value       = aws_elasticache_replication_group.this.port
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group."
  value       = aws_elasticache_subnet_group.this.name
}

output "parameter_group_name" {
  description = "Name of the Redis parameter group."
  value       = aws_elasticache_parameter_group.this.name
}

output "cloudwatch_log_group_names" {
  description = "CloudWatch log groups receiving Redis logs."
  value = {
    for log_type, log_group in aws_cloudwatch_log_group.redis :
    log_type => log_group.name
  }
}