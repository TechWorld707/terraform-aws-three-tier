variable "name" {
  description = "Name prefix applied to security resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) >= 3
    error_message = "name must contain at least three characters."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where security groups are created."
  type        = string

  validation {
    condition     = length(trimspace(var.vpc_id)) > 0
    error_message = "vpc_id must not be empty."
  }
}

variable "alb_ingress_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the public ALB."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.alb_ingress_cidrs :
      can(cidrnetmask(cidr))
    ])
    error_message = "Every ALB ingress value must be a valid IPv4 CIDR block."
  }
}

variable "alb_ingress_ports" {
  description = "Ports exposed by the public ALB."
  type        = set(number)
  default     = [80, 443]

  validation {
    condition = alltrue([
      for port in var.alb_ingress_ports :
      port >= 1 && port <= 65535
    ])
    error_message = "Every ALB ingress port must be between 1 and 65535."
  }
}

variable "application_port" {
  description = "Container port exposed by the ECS application."
  type        = number
  default     = 8080

  validation {
    condition     = var.application_port >= 1 && var.application_port <= 65535
    error_message = "application_port must be between 1 and 65535."
  }
}

variable "postgres_port" {
  description = "PostgreSQL port accepted from the ECS security group."
  type        = number
  default     = 5432
}

variable "redis_port" {
  description = "Redis port accepted from the ECS security group."
  type        = number
  default     = 6379
}

variable "database_username" {
  description = "Username stored with the generated database password."
  type        = string
  default     = "app"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{2,31}$", var.database_username))
    error_message = "database_username must start with a letter and contain 3 to 32 letters, digits, or underscores."
  }
}

variable "kms_deletion_window_days" {
  description = "Waiting period before permanent KMS key deletion."
  type        = number
  default     = 7

  validation {
    condition = (
      var.kms_deletion_window_days >= 7 &&
      var.kms_deletion_window_days <= 30
    )
    error_message = "kms_deletion_window_days must be between 7 and 30."
  }
}

variable "secret_recovery_window_days" {
  description = "Recovery period for a deleted Secrets Manager secret."
  type        = number
  default     = 7

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

variable "tags" {
  description = "Additional tags applied to security resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC, used for internal DNS egress."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}