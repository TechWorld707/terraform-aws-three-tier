output "state_bucket_name" {
  description = "S3 bucket used for Terraform state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_kms_key_arn" {
  description = "KMS key used to encrypt Terraform state."
  value       = aws_kms_key.terraform_state.arn
}

output "github_environment_role_arns" {
  description = "OIDC deployment role ARN for each GitHub environment."
  value       = { for environment, role in aws_iam_role.github_environment : environment => role.arn }
}

output "backend_configuration_examples" {
  description = "Values to place in each environment's backend configuration."
  value = {
    for environment in var.environments : environment => {
      bucket       = aws_s3_bucket.terraform_state.id
      key          = "${var.project_name}/${environment}/terraform.tfstate"
      region       = var.aws_region
      encrypt      = true
      kms_key_id   = aws_kms_key.terraform_state.arn
      use_lockfile = true
    }
  }
}
