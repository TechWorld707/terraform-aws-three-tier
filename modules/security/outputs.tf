output "alb_security_group_id" {
  description = "Security group ID assigned to the public ALB."
  value       = aws_security_group.alb.id
}

output "ecs_security_group_id" {
  description = "Security group ID assigned to ECS Fargate tasks."
  value       = aws_security_group.ecs.id
}

output "rds_security_group_id" {
  description = "Security group ID assigned to RDS PostgreSQL."
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "Security group ID assigned to ElastiCache Redis."
  value       = aws_security_group.redis.id
}

output "application_kms_key_id" {
  description = "ID of the application KMS key."
  value       = aws_kms_key.application.key_id
}

output "application_kms_key_arn" {
  description = "ARN of the application KMS key."
  value       = aws_kms_key.application.arn
}

output "database_credentials_secret_arn" {
  description = "ARN of the Secrets Manager database credentials secret."
  value       = aws_secretsmanager_secret.database_credentials.arn
}

output "database_credentials_secret_name" {
  description = "Name of the Secrets Manager database credentials secret."
  value       = aws_secretsmanager_secret.database_credentials.name
}

output "database_username" {
  description = "Generated database credential username."
  value       = var.database_username
}

output "database_password" {
  description = "Generated database password used by the future RDS module."
  value       = random_password.database.result
  sensitive   = true
}

output "redis_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing the Redis authentication token."
  value       = aws_secretsmanager_secret.redis_credentials.arn
}

output "redis_credentials_secret_name" {
  description = "Name of the Redis authentication secret."
  value       = aws_secretsmanager_secret.redis_credentials.name
}

output "redis_auth_token" {
  description = "Generated Redis authentication token."
  value       = random_password.redis.result
  sensitive   = true
}