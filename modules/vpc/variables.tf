variable "name" {
  description = "Name prefix applied to VPC resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name)) >= 3
    error_message = "name must contain at least three characters."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block assigned to the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability Zones used by the VPC."
  type        = list(string)

  validation {
    condition = (
      length(var.availability_zones) >= 2 &&
      length(distinct(var.availability_zones)) == length(var.availability_zones)
    )
    error_message = "Provide at least two unique Availability Zones."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public load-balancer and NAT gateway subnets."
  type        = list(string)

  validation {
    condition = (
      length(var.public_subnet_cidrs) >= 2 &&
      alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    )
    error_message = "Provide at least two valid public subnet CIDR blocks."
  }
}

variable "private_application_subnet_cidrs" {
  description = "CIDR blocks for private ECS application subnets."
  type        = list(string)

  validation {
    condition = (
      length(var.private_application_subnet_cidrs) >= 2 &&
      alltrue([
        for cidr in var.private_application_subnet_cidrs :
        can(cidrnetmask(cidr))
      ])
    )
    error_message = "Provide at least two valid private application subnet CIDR blocks."
  }
}

variable "isolated_database_subnet_cidrs" {
  description = "CIDR blocks for isolated RDS and ElastiCache subnets."
  type        = list(string)

  validation {
    condition = (
      length(var.isolated_database_subnet_cidrs) >= 2 &&
      alltrue([
        for cidr in var.isolated_database_subnet_cidrs :
        can(cidrnetmask(cidr))
      ])
    )
    error_message = "Provide at least two valid isolated database subnet CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  description = "Whether NAT gateways should be created for private application subnets."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use one shared NAT gateway when true, or one per Availability Zone when false."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Whether VPC Flow Logs should be sent to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Number of days CloudWatch retains VPC Flow Logs."
  type        = number
  default     = 30

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365],
      var.flow_log_retention_days
    )
    error_message = "flow_log_retention_days must be a supported retention period."
  }
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}