# ECS Services for 5-Node TNT Pipeline Cluster (Fixed Counts)

# Service 1: Coordinator (always running)
resource "aws_ecs_service" "coordinator" {
  name            = "coordinator"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.coordinator.arn
  desired_count   = 1
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

  # Placement constraints to ensure coordinator runs on different AZ
  placement_constraints {
    type = "distinctInstance"
  }

  tags = {
    Name        = "TNT Pipeline Coordinator"
    Environment = var.environment
    NodeRole    = "file_scanner"
    Purpose     = "Cluster coordination and file discovery"
  }

  depends_on = [
    aws_service_discovery_service.tnt_pipeline,
    aws_ecs_task_definition.coordinator,
    null_resource.db_migration # Wait for migration to complete
  ]
}

# Services 2-3: ETL Workers (fixed count: 2)
resource "aws_ecs_service" "etl_workers" {
  name            = "etl-workers"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.etl_worker_cluster.arn
  desired_count   = 2 # Fixed count: 2 ETL workers
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
    Purpose     = "Heavy ETL processing"
  }

  depends_on = [
    aws_service_discovery_service.tnt_pipeline,
    aws_ecs_task_definition.etl_worker_cluster,
    null_resource.db_migration # Wait for migration to complete
  ]
}

# Services 4-5: Balanced Workers (fixed count: 2)
resource "aws_ecs_service" "balanced_workers" {
  name            = "balanced-workers"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.balanced_worker.arn
  desired_count   = 2 # Fixed count: 2 balanced workers
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
    Purpose     = "Mixed workload processing"
  }

  depends_on = [
    aws_service_discovery_service.tnt_pipeline,
    aws_ecs_task_definition.balanced_worker,
    null_resource.db_migration # Wait for migration to complete
  ]
}

# Summary of 5-Node Fixed Cluster:
# 1 Coordinator (file_scanner role)
# 2 ETL Workers (etl_worker role) 
# 2 Balanced Workers (balanced role)
# Total: 5 nodes with predictable costs
# Manual scaling: Change desired_count to increase nodes

