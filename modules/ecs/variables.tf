variable "name" {
  description = "Name prefix applied to ECS platform resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) >= 3
    error_message = "name must contain at least three characters."
  }
}

variable "vpc_id" {
  description = "VPC ID used by the ALB target group."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs used by the Application Load Balancer."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "Provide at least two public subnet IDs."
  }
}

variable "private_subnet_ids" {
  description = "Private application subnet IDs used by ECS Fargate."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "Provide at least two private subnet IDs."
  }
}

variable "alb_security_group_id" {
  description = "Security group ID assigned to the ALB."
  type        = string
}

variable "ecs_security_group_id" {
  description = "Security group ID assigned to ECS tasks."
  type        = string
}

variable "container_port" {
  description = "Port exposed by the application container."
  type        = number
  default     = 8080

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be between 1 and 65535."
  }
}

variable "image_tag" {
  description = "Immutable ECR image tag deployed by the task definition."
  type        = string
  default     = "bootstrap"

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]{1,128}$", var.image_tag))
    error_message = "image_tag must be a valid container image tag."
  }
}

variable "desired_count" {
  description = "Desired number of ECS tasks. Use zero before the first image is pushed."
  type        = number
  default     = 0

  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count cannot be negative."
  }
}

variable "task_cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "task_cpu must be a supported Fargate CPU value."
  }
}

variable "task_memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 512

  validation {
    condition     = var.task_memory >= 512
    error_message = "task_memory must be at least 512 MiB."
  }
}

variable "health_check_path" {
  description = "HTTP path used by the ALB target-group health check."
  type        = string
  default     = "/health"

  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "health_check_path must begin with a forward slash."
  }
}

variable "log_retention_days" {
  description = "CloudWatch retention period for ECS application logs."
  type        = number
  default     = 30

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365],
      var.log_retention_days
    )
    error_message = "log_retention_days must be a supported retention period."
  }
}

variable "enable_execute_command" {
  description = "Enable ECS Exec for controlled container troubleshooting."
  type        = bool
  default     = true
}

variable "enable_deletion_protection" {
  description = "Enable ALB deletion protection."
  type        = bool
  default     = false
}

variable "container_environment" {
  description = "Non-sensitive environment variables passed to the container."
  type        = map(string)
  default     = {}
}

variable "container_secrets" {
  description = "Map of container environment names to Secrets Manager secret ARNs."
  type        = map(string)
  default     = {}
}

variable "kms_key_arns" {
  description = "KMS key ARNs that the ECS task may use for decryption."
  type        = set(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "S3 bucket ARNs that the ECS task may access."
  type        = set(string)
  default     = []
}

variable "tags" {
  description = "Additional tags applied to ECS platform resources."
  type        = map(string)
  default     = {}
}

variable "ecr_force_delete" {
  description = "Allow ECR images to be deleted when the repository is destroyed."
  type        = bool
  default     = false
}

variable "ecr_kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt ECR images."
  type        = string
  default     = null
  nullable    = true
}

variable "ecs_desired_count" {
  description = "Number of ECS application tasks to run."
  type        = number
  default     = 0

  validation {
    condition     = var.ecs_desired_count >= 0 && var.ecs_desired_count <= 10
    error_message = "ecs_desired_count must be between 0 and 10."
  }
}

variable "container_image_tag" {
  description = "Immutable container image tag deployed to ECS."
  type        = string
  default     = "bootstrap"

  validation {
    condition     = can(regex("^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$", var.container_image_tag))
    error_message = "container_image_tag must be a valid Docker image tag."
  }
}

variable "log_kms_key_arn" {
  description = "Optional KMS key ARN used to encrypt ECS CloudWatch logs."
  type        = string
  default     = null
  nullable    = true
}