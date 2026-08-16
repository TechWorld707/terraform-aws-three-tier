variable "name" {
  description = "Name prefix used for RDS resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "database_name" {
  description = "Name of the PostgreSQL application database."
  type        = string
  default     = "profiles"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]*$", var.database_name))
    error_message = "database_name must begin with a letter and contain only letters, numbers, and underscores."
  }
}

variable "database_username" {
  description = "PostgreSQL master username."
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "PostgreSQL master password."
  type        = string
  sensitive   = true
}

variable "database_subnet_ids" {
  description = "Isolated subnet IDs used by the RDS subnet group."
  type        = list(string)

  validation {
    condition     = length(var.database_subnet_ids) >= 2
    error_message = "At least two database subnet IDs are required for Multi-AZ readiness."
  }
}

variable "security_group_id" {
  description = "Security group attached to the RDS instance."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt RDS storage and Performance Insights."
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version."
  type        = string
  default     = "17"
}

variable "parameter_group_family" {
  description = "PostgreSQL parameter-group family matching the engine major version."
  type        = string
  default     = "postgres17"
}

variable "instance_class" {
  description = "RDS database instance class."
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Initial RDS storage allocation in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GiB."
  }
}

variable "max_allocated_storage" {
  description = "Maximum storage autoscaling limit in GiB. Set to 0 to disable autoscaling."
  type        = number
  default     = 50

  validation {
    condition     = var.max_allocated_storage == 0 || var.max_allocated_storage >= 20
    error_message = "max_allocated_storage must be 0 or at least 20 GiB."
  }
}

variable "storage_type" {
  description = "RDS storage type."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3"], var.storage_type)
    error_message = "storage_type must be gp2 or gp3."
  }
}

variable "multi_az" {
  description = "Deploy an RDS standby in another Availability Zone."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days automated RDS backups are retained."
  type        = number
  default     = 1

  validation {
    condition     = var.backup_retention_days >= 0 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 0 and 35."
  }
}

variable "deletion_protection" {
  description = "Prevent accidental deletion of the RDS instance."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot when deleting the database."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply database modifications immediately."
  type        = bool
  default     = true
}

variable "performance_insights_enabled" {
  description = "Enable RDS Performance Insights."
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced Monitoring interval in seconds. Zero disables it."
  type        = number
  default     = 0

  validation {
    condition = contains(
      [0, 1, 5, 10, 15, 30, 60],
      var.monitoring_interval
    )
    error_message = "monitoring_interval must be 0, 1, 5, 10, 15, 30, or 60 seconds."
  }
}

variable "log_exports" {
  description = "PostgreSQL logs exported to CloudWatch."
  type        = set(string)
  default = [
    "postgresql",
    "upgrade"
  ]

  validation {
    condition = alltrue([
      for log in var.log_exports :
      contains(["postgresql", "upgrade"], log)
    ])
    error_message = "log_exports may contain only postgresql and upgrade."
  }
}

variable "tags" {
  description = "Additional tags applied to RDS resources."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "Number of days RDS logs are retained in CloudWatch."
  type        = number
  default     = 30

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365],
      var.log_retention_days
    )
    error_message = "log_retention_days must be a supported CloudWatch retention value."
  }
}

variable "database_parameters" {
  description = "Custom PostgreSQL parameter-group values."
  type        = map(string)

  default = {
    "log_min_duration_statement" = "1000"
  }
}

variable "final_snapshot_identifier" {
  description = "Final snapshot name used when skip_final_snapshot is false."
  type        = string
  default     = null
  nullable    = true
}