output "ecs_cluster_id" {
  description = "ID of the ECS Cluster"
  value       = aws_ecs_cluster.this.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.this.name
}


output "ecs_security_group_id" {
  description = "Security group ID for ECS Fargate tasks"
  value       = aws_security_group.fargate.id
}

output "fargate_security_group_id" {
  description = "Security group ID for ECS Fargate tasks"
  value       = aws_security_group.fargate.id
}

output "subnet_id" {
  description = "First subnet ID for ECS tasks"
  value       = var.subnet_ids[0]
}

output "subnet_ids" {
  description = "All subnet IDs for ECS tasks"
  value       = var.subnet_ids
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

# ETL service outputs removed - now using task-only mode

output "go_api_alb_dns_name" {
  description = "DNS name of the Go API Application Load Balancer"
  value       = aws_lb.go_api.dns_name
}

output "go_api_alb_zone_id" {
  description = "Zone ID of the Go API Application Load Balancer"
  value       = aws_lb.go_api.zone_id
}

output "go_api_url" {
  description = "Full URL of the Go API service"
  value       = "http://${aws_lb.go_api.dns_name}"
}
