output "db_instance_endpoint" {
  description = "RDS endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "RDS hostname (no port)"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "DB name"
  value       = aws_db_instance.this.db_name
}

output "db_credentials_secret_arn" {
  description = "ARN of the secret storing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "db_credentials_secret_name" {
  description = "Name of the secret storing DB credentials"
  value       = aws_secretsmanager_secret.db_credentials.name
}