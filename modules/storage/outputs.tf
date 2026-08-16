output "bucket_name" {
  description = "Name of the application submission archive bucket."
  value       = aws_s3_bucket.submissions.id
}

output "bucket_arn" {
  description = "ARN of the application submission archive bucket."
  value       = aws_s3_bucket.submissions.arn
}

output "bucket_domain_name" {
  description = "Regional domain name of the archive bucket."
  value       = aws_s3_bucket.submissions.bucket_regional_domain_name
}

output "submissions_prefix" {
  description = "S3 object prefix used for archived submissions."
  value       = "submissions/"
}

output "kms_key_arn" {
  description = "KMS key ARN used to encrypt submission objects."
  value       = var.kms_key_arn
}

output "s3_uri" {
  description = "S3 URI of the application submission archive bucket."
  value       = "s3://${aws_s3_bucket.submissions.id}"
}