output "mysql_host" {
  description = "MySQL hostname, without port."
  value       = aws_db_instance.mysql.address
}

output "mysql_port" {
  value = aws_db_instance.mysql.port
}

output "database_name" {
  value = aws_db_instance.mysql.db_name
}

output "master_username" {
  value = aws_db_instance.mysql.username
}

output "master_password_secret_arn" {
  description = "Retrieve the password from this Secrets Manager secret using an authorized AWS identity."
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
}

output "vpc_id" {
  value = aws_vpc.database.id
}

output "subnet_ids" {
  value = aws_subnet.database[*].id
}

output "application_security_group_id" {
  description = "Attach to application instances in this VPC to allow MySQL access."
  value       = aws_security_group.client.id
}
