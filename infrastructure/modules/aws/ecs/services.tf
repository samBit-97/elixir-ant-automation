# Go API service
resource "aws_ecs_service" "go_api" {
  name            = "go-api"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.go_api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.fargate.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.go_api.arn
    container_name   = "go-api"
    container_port   = 8081
  }

  depends_on = [aws_lb_listener.go_api]

  tags = {
    Name        = "Go API Service"
    Environment = var.environment
    Purpose     = "External API for ETL pipeline"
  }
}

