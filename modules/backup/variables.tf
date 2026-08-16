variable "name" {
  description = "Name used for AWS Backup resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt the backup vault."
  type        = string
}

variable "resource_arns" {
  description = "ARNs of AWS resources protected by the backup plan."
  type        = set(string)

  validation {
    condition     = length(var.resource_arns) >= 1
    error_message = "At least one resource ARN must be selected for backup."
  }
}

variable "schedule_expression" {
  description = "AWS Backup schedule expressed as an EventBridge cron expression."
  type        = string
  default     = "cron(0 5 * * ? *)"
}

variable "start_window_minutes" {
  description = "Minutes AWS Backup may wait before starting a scheduled job."
  type        = number
  default     = 60

  validation {
    condition     = var.start_window_minutes >= 60
    error_message = "start_window_minutes must be at least 60."
  }
}

variable "completion_window_minutes" {
  description = "Minutes allowed for a backup job to complete."
  type        = number
  default     = 180

  validation {
    condition     = var.completion_window_minutes >= 60
    error_message = "completion_window_minutes must be at least 60."
  }
}

variable "delete_after_days" {
  description = "Days before recovery points are deleted."
  type        = number
  default     = 7

  validation {
    condition     = var.delete_after_days >= 1
    error_message = "delete_after_days must be at least one."
  }
}

variable "enable_continuous_backup" {
  description = "Enable point-in-time continuous backup for supported resources."
  type        = bool
  default     = false
}

variable "enable_vault_lock" {
  description = "Enable AWS Backup Vault Lock."
  type        = bool
  default     = false
}

variable "vault_lock_min_retention_days" {
  description = "Minimum retention enforced by Backup Vault Lock."
  type        = number
  default     = 7

  validation {
    condition     = var.vault_lock_min_retention_days >= 1
    error_message = "vault_lock_min_retention_days must be at least one."
  }
}

variable "tags" {
  description = "Additional tags applied to backup resources."
  type        = map(string)
  default     = {}
}