output "ecr_repository_name" {
  description = "Name of the application ECR repository."
  value       = aws_ecr_repository.application.name
}

output "ecr_repository_url" {
  description = "URL used to push and pull the application container image."
  value       = aws_ecr_repository.application.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the application ECR repository."
  value       = aws_ecr_repository.application.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "ecs_service_name" {
  description = "Name of the ECS application service."
  value       = aws_ecs_service.application.name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition."
  value       = aws_ecs_task_definition.application.arn
}

output "task_execution_role_arn" {
  description = "ARN of the IAM role used by ECS to start tasks."
  value       = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  description = "ARN used by the running application."
  value       = aws_iam_role.task.arn
}

output "load_balancer_arn" {
  description = "ARN of the public Application Load Balancer."
  value       = aws_lb.application.arn
}

output "load_balancer_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = aws_lb.application.dns_name
}

output "load_balancer_zone_id" {
  description = "Route 53 hosted-zone ID of the Application Load Balancer."
  value       = aws_lb.application.zone_id
}

output "target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.application.arn
}

output "http_listener_arn" {
  description = "ARN of the ALB HTTP listener."
  value       = aws_lb_listener.http.arn
}

output "application_log_group_name" {
  description = "CloudWatch log group receiving application container logs."
  value       = aws_cloudwatch_log_group.application.name
}