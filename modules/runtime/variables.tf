variable "name" {
  description = "Name used for the application runtime secret."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the runtime secret."
  type        = string
}

variable "secret_recovery_window_days" {
  description = "Secrets Manager recovery window. Zero allows immediate development teardown."
  type        = number
  default     = 0

  validation {
    condition = (
      var.secret_recovery_window_days == 0 ||
      (
        var.secret_recovery_window_days >= 7 &&
        var.secret_recovery_window_days <= 30
      )
    )

    error_message = "secret_recovery_window_days must be 0 or between 7 and 30."
  }
}

variable "database_host" {
  description = "Private RDS PostgreSQL hostname."
  type        = string
}

variable "database_port" {
  description = "PostgreSQL listener port."
  type        = number
  default     = 5432
}

variable "database_name" {
  description = "PostgreSQL application database name."
  type        = string
}

variable "database_username" {
  description = "PostgreSQL application username."
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "PostgreSQL application password."
  type        = string
  sensitive   = true
}

variable "redis_host" {
  description = "Private Redis primary endpoint."
  type        = string
}

variable "redis_port" {
  description = "Redis TLS listener port."
  type        = number
  default     = 6379
}

variable "redis_auth_token" {
  description = "Redis authentication token."
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "Application submission archive bucket name."
  type        = string
}

variable "aws_region" {
  description = "AWS region used by the application."
  type        = string
}

variable "tags" {
  description = "Additional tags applied to runtime configuration resources."
  type        = map(string)
  default     = {}
}