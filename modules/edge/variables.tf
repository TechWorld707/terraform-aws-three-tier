variable "name" {
  description = "Name used for edge-platform resources."
  type        = string

  validation {
    condition = (
      length(var.name) >= 3 &&
      length(var.name) <= 40 &&
      can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.name))
    )

    error_message = "name must contain 3 to 40 lowercase letters, numbers, or hyphens."
  }
}

variable "alb_domain_name" {
  description = "DNS name of the Application Load Balancer API origin."
  type        = string
}

variable "frontend_source_directory" {
  description = "Absolute or root-relative path containing frontend static files."
  type        = string
}

variable "frontend_force_destroy" {
  description = "Allow deletion of the frontend bucket when it contains objects."
  type        = bool
  default     = false
}

variable "default_root_object" {
  description = "Default object returned by CloudFront."
  type        = string
  default     = "index.html"
}

variable "price_class" {
  description = "CloudFront edge-location price class."
  type        = string
  default     = "PriceClass_100"

  validation {
    condition = contains(
      [
        "PriceClass_100",
        "PriceClass_200",
        "PriceClass_All"
      ],
      var.price_class
    )

    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "enable_ipv6" {
  description = "Enable IPv6 for the CloudFront distribution."
  type        = bool
  default     = true
}

variable "waf_rate_limit" {
  description = "Maximum requests allowed per five-minute evaluation window from one IP address."
  type        = number
  default     = 1000

  validation {
    condition     = var.waf_rate_limit >= 100
    error_message = "waf_rate_limit must be at least 100."
  }
}

variable "domain_name" {
  description = "Optional custom application domain name."
  type        = string
  default     = null
  nullable    = true
}

variable "acm_certificate_arn" {
  description = "Optional us-east-1 ACM certificate ARN for CloudFront."
  type        = string
  default     = null
  nullable    = true
}

variable "tags" {
  description = "Additional tags applied to edge resources."
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN used to encrypt frontend objects and edge logs."
  type        = string
}

variable "waf_log_retention_days" {
  description = "Number of days to retain AWS WAF request logs."
  type        = number
  default     = 90

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.waf_log_retention_days
    )

    error_message = "waf_log_retention_days must be a supported CloudWatch Logs retention value."
  }
}