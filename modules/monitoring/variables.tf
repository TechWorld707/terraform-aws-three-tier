variable "name" {
  description = "Name used for monitoring and alerting resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region displayed in the CloudWatch dashboard."
  type        = string
}

variable "alarm_email" {
  description = "Optional email address that receives SNS alarm notifications."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true

  validation {
    condition = (
      var.alarm_email == null ||
      can(regex(
        "^[^@[:space:]]+@[^@[:space:]]+\\.[^@[:space:]]+$",
        var.alarm_email
      ))
    )

    error_message = "alarm_email must be null or a valid email address."
  }
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster being monitored."
  type        = string
}

variable "ecs_service_name" {
  description = "Name of the ECS service being monitored."
  type        = string
}

variable "load_balancer_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group."
  type        = string
}

variable "rds_instance_id" {
  description = "RDS database instance identifier."
  type        = string
}

variable "redis_replication_group_id" {
  description = "ElastiCache Redis replication-group identifier."
  type        = string
}

variable "ecs_cpu_threshold" {
  description = "ECS CPU utilization alarm threshold percentage."
  type        = number
  default     = 80
}

variable "ecs_memory_threshold" {
  description = "ECS memory utilization alarm threshold percentage."
  type        = number
  default     = 80
}

variable "rds_cpu_threshold" {
  description = "RDS CPU utilization alarm threshold percentage."
  type        = number
  default     = 80
}

variable "rds_free_storage_threshold_bytes" {
  description = "RDS low free-storage alarm threshold in bytes."
  type        = number
  default     = 2147483648
}

variable "redis_cpu_threshold" {
  description = "Redis engine CPU alarm threshold percentage."
  type        = number
  default     = 80
}

variable "redis_free_memory_threshold_bytes" {
  description = "Redis low-memory alarm threshold in bytes."
  type        = number
  default     = 52428800
}

variable "alb_5xx_threshold" {
  description = "ALB HTTP 5xx count that triggers an alarm."
  type        = number
  default     = 5
}

variable "alarm_evaluation_periods" {
  description = "Number of periods evaluated before triggering alarms."
  type        = number
  default     = 2

  validation {
    condition     = var.alarm_evaluation_periods >= 1
    error_message = "alarm_evaluation_periods must be at least one."
  }
}

variable "tags" {
  description = "Additional tags applied to monitoring resources."
  type        = map(string)
  default     = {}
}
