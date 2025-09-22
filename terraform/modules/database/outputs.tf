output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "database_address" {
  description = "RDS instance address"
  value       = aws_db_instance.main.address
}

output "database_port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "database_username" {
  description = "Database username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "database_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "database_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "database_availability_zone" {
  description = "RDS instance availability zone"
  value       = aws_db_instance.main.availability_zone
}

output "database_subnet_group_name" {
  description = "Database subnet group name"
  value       = aws_db_subnet_group.main.name
}

output "database_parameter_group_name" {
  description = "Database parameter group name"
  value       = aws_db_parameter_group.main.name
}

output "database_option_group_name" {
  description = "Database option group name"
  value       = aws_db_option_group.main.name
}

output "replica_endpoint" {
  description = "Read replica endpoint"
  value       = var.create_read_replica ? aws_db_instance.replica[0].endpoint : null
}

output "master_user_secret_arn" {
  description = "ARN of the master user secret (when manage_password is true)"
  value       = var.manage_password ? aws_db_instance.main.master_user_secret[0].secret_arn : null
  sensitive   = true
}
