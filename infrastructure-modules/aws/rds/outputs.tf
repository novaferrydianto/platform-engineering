output "endpoint" {
  description = "Connection endpoint"
  value       = aws_db_instance.this.endpoint
}

output "port" {
  description = "Database port"
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Initial database name"
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "Security group guarding the database"
  value       = aws_security_group.this.id
}

output "master_user_secret_arn" {
  description = "Secrets Manager secret holding the AWS-managed master credentials"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "kms_key_arn" {
  description = "KMS key encrypting storage, backups, and the master secret"
  value       = aws_kms_key.rds.arn
}
