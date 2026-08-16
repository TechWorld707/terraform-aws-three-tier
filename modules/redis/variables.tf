variable "name" {
  description = "Name used for ElastiCache resources."
  type        = string

  validation {
    condition = (
      length(var.name) <= 40 &&
      can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.name)) &&
      !strcontains(var.name, "--")
    )

    error_message = "name must begin with a lowercase letter, contain only lowercase letters, numbers and hyphens, and must not end with a hyphen."
  }
}

variable "subnet_ids" {
  description = "Private subnet IDs used by ElastiCache."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least two subnet IDs are required for high-availability readiness."
  }
}

variable "security_group_id" {
  description = "Security group attached to the Redis replication group."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used for encryption at rest."
  type        = string
}

variable "auth_token" {
  description = "Authentication token for encrypted Redis connections."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.auth_token) >= 16 && length(var.auth_token) <= 128
    error_message = "auth_token must contain between 16 and 128 characters."
  }
}

variable "engine_version" {
  description = "Redis OSS engine version."
  type        = string
  default     = "7.1"
}

variable "parameter_group_family" {
  description = "ElastiCache parameter-group family."
  type        = string
  default     = "redis7"
}

variable "node_type" {
  description = "ElastiCache node type."
  type        = string
  default     = "cache.t4g.micro"
}

variable "num_cache_clusters" {
  description = "Number of cache nodes in the replication group."
  type        = number
  default     = 1

  validation {
    condition     = var.num_cache_clusters >= 1 && var.num_cache_clusters <= 6
    error_message = "num_cache_clusters must be between 1 and 6."
  }
}

variable "automatic_failover_enabled" {
  description = "Enable automatic failover when replica nodes are present."
  type        = bool
  default     = false
}

variable "multi_az_enabled" {
  description = "Distribute Redis nodes across multiple Availability Zones."
  type        = bool
  default     = false
}

variable "snapshot_retention_limit" {
  description = "Number of days Redis snapshots are retained. Zero disables snapshots."
  type        = number
  default     = 0

  validation {
    condition     = var.snapshot_retention_limit >= 0 && var.snapshot_retention_limit <= 35
    error_message = "snapshot_retention_limit must be between 0 and 35."
  }
}

variable "apply_immediately" {
  description = "Apply Redis modifications immediately."
  type        = bool
  default     = true
}

variable "auto_minor_version_upgrade" {
  description = "Allow automatic minor Redis engine upgrades."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch retention period for Redis logs."
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

variable "tags" {
  description = "Additional tags applied to Redis resources."
  type        = map(string)
  default     = {}
}