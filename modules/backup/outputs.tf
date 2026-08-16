output "backup_vault_name" {
  description = "Name of the AWS Backup vault."
  value       = aws_backup_vault.this.name
}

output "backup_vault_arn" {
  description = "ARN of the AWS Backup vault."
  value       = aws_backup_vault.this.arn
}

output "backup_plan_id" {
  description = "ID of the AWS Backup plan."
  value       = aws_backup_plan.this.id
}

output "backup_plan_arn" {
  description = "ARN of the AWS Backup plan."
  value       = aws_backup_plan.this.arn
}

output "backup_role_arn" {
  description = "ARN of the AWS Backup service role."
  value       = aws_iam_role.backup.arn
}

output "protected_resource_arns" {
  description = "Resource ARNs selected by the backup plan."
  value       = var.resource_arns
}

output "vault_lock_enabled" {
  description = "Whether Backup Vault Lock is enabled."
  value       = var.enable_vault_lock
}