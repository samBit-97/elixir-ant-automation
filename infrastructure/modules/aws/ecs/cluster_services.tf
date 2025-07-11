# ECS Services for 4-Node LibCluster Architecture  
# 4 persistent workers with role-based deployment
# File scanner runs as one-shot task (manually triggered)

#########################################
# Nodes 1-2: ETL Workers
# Dedicated ETL processing (auto-scaling 2-10)
#########################################

resource "aws_ecs_service" "etl_workers" {
  name            = "etl-workers"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.etl_worker.arn
  desired_count   = 2 # Initial count: auto-scales 2-10
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.cluster.id]
    assign_public_ip = true
  }

  # Enable service discovery
  service_registries {
    registry_arn = aws_service_discovery_service.tnt_pipeline.arn
  }

  # Placement constraints
  placement_constraints {
    type = "distinctInstance"
  }

  tags = {
    Name        = "TNT Pipeline ETL Workers"
    Environment = var.environment
    NodeRole    = "etl_worker"
    Purpose     = "Dedicated ETL processing"
  }

  depends_on = [
    aws_service_discovery_service.tnt_pipeline,
    aws_ecs_task_definition.etl_worker,
    null_resource.db_migration
  ]
}

#########################################
# Nodes 3-4: Balanced Workers
# Multi-purpose workers (auto-scaling 2-8)
#########################################

resource "aws_ecs_service" "balanced_workers" {
  name            = "balanced-workers"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.balanced_worker.arn
  desired_count   = 2 # Initial count: auto-scales 2-8
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.cluster.id]
    assign_public_ip = true
  }

  # Enable service discovery
  service_registries {
    registry_arn = aws_service_discovery_service.tnt_pipeline.arn
  }

  # Placement constraints
  placement_constraints {
    type = "distinctInstance"
  }

  tags = {
    Name        = "TNT Pipeline Balanced Workers"
    Environment = var.environment
    NodeRole    = "balanced"
    Purpose     = "Multi-purpose processing (persist_results, dashboard_updates, monitoring)"
  }

  depends_on = [
    aws_service_discovery_service.tnt_pipeline,
    aws_ecs_task_definition.balanced_worker,
    null_resource.db_migration
  ]
}

#########################################
# Architecture Summary
#########################################

# 4-Node LibCluster Architecture:
# Nodes 1-2: ETL Workers (etl_files queue) - Auto-scaling 2-10 instances
# Nodes 3-4: Balanced Workers (persist_results, dashboard_updates, monitoring queues) - Auto-scaling 2-8 instances
# File Scanner: One-shot task (manually triggered) - Creates ETL jobs and exits
# Total: 4-18 persistent instances + on-demand scanner with LibCluster coordination