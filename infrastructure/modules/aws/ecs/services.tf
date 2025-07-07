resource "aws_ecs_service" "etl_worker" {
  name            = "etl-worker"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.etl_worker.arn
  desired_count   = 0  # Start with 0, scale up when jobs are queued
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.fargate.id]
    assign_public_ip = true
  }

  
  tags = {
    Name = "ETL Worker"
    Environment = var.environment
    Purpose = "Oban job processing"
  }
}

