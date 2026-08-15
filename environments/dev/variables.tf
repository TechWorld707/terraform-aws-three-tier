variable "aws_region" {
  description = "AWS region used by the development environment."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.aws_region))
    error_message = "aws_region must be a valid AWS region name."
  }
}

variable "project_name" {
  description = "Name used to identify project resources."
  type        = string
  default     = "three-tier-platform"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "environment must be dev, staging, or production."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the development VPC."
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zone_count" {
  description = "Number of Availability Zones used by the environment."
  type        = number
  default     = 2

  validation {
    condition = (
      var.availability_zone_count >= 2 &&
      var.availability_zone_count <= 3
    )
    error_message = "availability_zone_count must be between 2 and 3."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create NAT gateway infrastructure."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway to reduce development cost."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Whether VPC Flow Logs should be enabled."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "CloudWatch retention period for VPC Flow Logs."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags applied to development resources."
  type        = map(string)
  default     = {}
}


variable "database_username" {
  description = "Username stored in the development database credentials secret."
  type        = string
  default     = "app"
}

variable "kms_deletion_window_days" {
  description = "Waiting period before permanent deletion of the development application KMS key."
  type        = number
  default     = 7
}

variable "secret_recovery_window_days" {
  description = "Recovery window for the development database credentials secret."
  type        = number
  default     = 0
}