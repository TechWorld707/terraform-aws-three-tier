variable "aws_region" {
  description = "AWS region for the state bucket, KMS key, and budget resources."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}(-gov)?-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region name such as eu-west-2."
  }
}

variable "project_name" {
  description = "Name used to identify and tag project resources."
  type        = string
  default     = "three-tier-platform"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.project_name))
    error_message = "project_name must be 3-31 lowercase letters, numbers, or hyphens."
  }
}

variable "github_owner" {
  description = "GitHub user or organization that owns the repository."
  type        = string
  default     = "TechWorld707"
}

variable "github_repository" {
  description = "GitHub repository name trusted by AWS OIDC."
  type        = string
  default     = "terraform-aws-three-tier"
}

variable "github_oidc_subject_prefix" {
  description = "Immutable GitHub Actions OIDC subject prefix containing the owner and repository IDs."
  type        = string
  default     = "repo:TechWorld707@313882919/terraform-aws-three-tier@1333062767"
}

variable "environments" {
  description = "GitHub environments that receive separate AWS deployment roles."
  type        = set(string)
  default     = ["dev", "staging", "production"]

  validation {
    condition     = length(var.environments) > 0 && alltrue([for environment in var.environments : contains(["dev", "staging", "production"], environment)])
    error_message = "environments may contain only dev, staging, and production."
  }
}

variable "monthly_budget_usd" {
  description = "Monthly project budget threshold in USD."
  type        = number
  default     = 2

  validation {
    condition     = var.monthly_budget_usd >= 1 && var.monthly_budget_usd <= 1000
    error_message = "monthly_budget_usd must be between 1 and 1000."
  }
}

variable "budget_notification_email" {
  description = "Optional email address for AWS Budget alerts. Leave null to omit email notifications."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.budget_notification_email == null || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.budget_notification_email))
    error_message = "budget_notification_email must be null or a valid email address."
  }
}
