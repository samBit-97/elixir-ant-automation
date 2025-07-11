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

# Cluster-specific outputs
output "cluster_service_discovery_namespace" {
  description = "Service discovery namespace for the cluster"
  value       = aws_service_discovery_private_dns_namespace.tnt_pipeline.name
}

output "cluster_service_discovery_service" {
  description = "Service discovery service name"
  value       = aws_service_discovery_service.tnt_pipeline.name
}

output "cluster_security_group_id" {
  description = "Security group ID for cluster communication"
  value       = aws_security_group.cluster.id
}

output "coordinator_service_name" {
  description = "ECS service name for coordinator"
  value       = aws_ecs_service.coordinator.name
}

output "etl_workers_service_name" {
  description = "ECS service name for ETL workers"
  value       = aws_ecs_service.etl_workers.name
}

output "balanced_workers_service_name" {
  description = "ECS service name for balanced workers"
  value       = aws_ecs_service.balanced_workers.name
}

output "cluster_secret_arn" {
  description = "ARN of the cluster secret for Erlang distribution"
  value       = aws_secretsmanager_secret.cluster_secret.arn
}

output "migration_task_definition_arn" {
  description = "ARN of the database migration task definition"
  value       = aws_ecs_task_definition.db_migration.arn
}

# Auto-scaling outputs
output "etl_workers_autoscaling_target_resource_id" {
  description = "Resource ID of the ETL workers auto-scaling target"
  value       = aws_appautoscaling_target.etl_workers.resource_id
}

output "balanced_workers_autoscaling_target_resource_id" {
  description = "Resource ID of the balanced workers auto-scaling target"
  value       = aws_appautoscaling_target.balanced_workers.resource_id
}

output "etl_workers_scale_up_policy_arn" {
  description = "ARN of the ETL workers scale-up policy"
  value       = aws_appautoscaling_policy.etl_workers_scale_up.arn
}

output "balanced_workers_scale_up_policy_arn" {
  description = "ARN of the balanced workers scale-up policy"
  value       = aws_appautoscaling_policy.balanced_workers_scale_up.arn
}

output "cloudwatch_metric_namespace" {
  description = "CloudWatch namespace for TNT Pipeline metrics"
  value       = "TntPipeline/QueueBalancer"
}

output "autoscaling_iam_role_arn" {
  description = "ARN of the ECS auto-scaling IAM role"
  value       = aws_iam_role.ecs_autoscaling_role.arn
}
