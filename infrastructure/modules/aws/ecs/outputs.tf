output "ecs_cluster_id" {
  description = "ID of the ECS Cluster"
  value       = aws_ecs_cluster.this.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.this.name
}


output "ecs_security_group_id" {
  description = "Security group ID for ECS EC2 instances"
  value       = aws_security_group.ecs.id
}

output "cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.this.name
}

output "file_scanner_task_definition_arn" {
  description = "ARN of the file scanner task definition"
  value       = aws_ecs_task_definition.file_scanner.arn
}

output "etl_task_definition_arn" {
  description = "ARN of the ETL worker task definition"
  value       = aws_ecs_task_definition.etl_worker.arn
}

output "etl_service_name" {
  description = "Name of the ETL worker service"
  value       = aws_ecs_service.etl_worker.name
}

output "etl_service_arn" {
  description = "ARN of the ETL worker service"
  value       = aws_ecs_service.etl_worker.id
}
