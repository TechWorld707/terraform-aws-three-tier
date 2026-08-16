output "dashboard_name" {
  description = "Name of the CloudWatch operations dashboard."
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS alarm topic."
  value       = aws_sns_topic.alerts.arn
}

output "alarm_kms_key_arn" {
  description = "ARN of the KMS key encrypting SNS alerts."
  value       = aws_kms_key.alerts.arn
}

output "alarm_names" {
  description = "Names of the CloudWatch metric alarms."
  value = {
    for alarm_key, alarm in aws_cloudwatch_metric_alarm.this :
    alarm_key => alarm.alarm_name
  }
}
