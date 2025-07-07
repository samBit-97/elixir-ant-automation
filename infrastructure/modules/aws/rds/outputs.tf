output "endpoint" {
  value = aws_db_instance.this.endpoint
}

output "username" {
  value = aws_db_instance.this.username
}

output "db_name" {
  value = aws_db_instance.this.id
}

output "db_address" {
  description = "RDS endpoint address"
  value       = aws_db_instance.this.address
}
