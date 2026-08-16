variable "name" {
  description = "Name prefix used for the application archive bucket."
  type        = string

  validation {
    condition = (
      length(var.name) >= 3 &&
      length(var.name) <= 40 &&
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.name))
    )

    error_message = "name must contain 3 to 45 lowercase letters, numbers, or hyphens."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN used for S3 object encryption."
  type        = string
}

variable "force_destroy" {
  description = "Allow deletion of the bucket when it contains objects and versions."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable S3 object versioning."
  type        = bool
  default     = true
}

variable "object_expiration_days" {
  description = "Days before archived submission objects expire. Zero disables expiration."
  type        = number
  default     = 90

  validation {
    condition     = var.object_expiration_days == 0 || var.object_expiration_days >= 1
    error_message = "object_expiration_days must be zero or at least one day."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "Days before noncurrent object versions expire."
  type        = number
  default     = 30

  validation {
    condition     = var.noncurrent_version_expiration_days >= 1
    error_message = "noncurrent_version_expiration_days must be at least one day."
  }
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Days before incomplete multipart uploads are removed."
  type        = number
  default     = 7

  validation {
    condition     = var.abort_incomplete_multipart_upload_days >= 1
    error_message = "abort_incomplete_multipart_upload_days must be at least one day."
  }
}

variable "tags" {
  description = "Additional tags applied to storage resources."
  type        = map(string)
  default     = {}
}