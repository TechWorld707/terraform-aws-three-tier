output "runtime_secret_arn" {
  description = "ARN of the application runtime secret."
  value       = aws_secretsmanager_secret.runtime.arn
}

output "runtime_secret_name" {
  description = "Name of the application runtime secret."
  value       = aws_secretsmanager_secret.runtime.name
}

output "ecs_container_secrets" {
  description = "Secrets Manager references used by the ECS task definition."

  value = {
    DATABASE_URL = "${aws_secretsmanager_secret.runtime.arn}:DATABASE_URL::"
    REDIS_URL    = "${aws_secretsmanager_secret.runtime.arn}:REDIS_URL::"
  }
}