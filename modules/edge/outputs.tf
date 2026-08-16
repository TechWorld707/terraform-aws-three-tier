output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.arn
}

output "cloudfront_domain_name" {
  description = "Generated CloudFront HTTPS hostname."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "Route 53 hosted-zone ID used by CloudFront aliases."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "frontend_bucket_name" {
  description = "Name of the private frontend S3 bucket."
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "ARN of the private frontend S3 bucket."
  value       = aws_s3_bucket.frontend.arn
}

output "waf_web_acl_arn" {
  description = "ARN of the CloudFront WAF web ACL."
  value       = aws_wafv2_web_acl.cloudfront.arn
}

output "application_url" {
  description = "HTTPS URL used to access the application."
  value = (
    var.domain_name != null
    ? "https://${var.domain_name}"
    : "https://${aws_cloudfront_distribution.this.domain_name}"
  )
}