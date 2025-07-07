# Auto-scaling configuration for ETL workers
# Enables scaling from 0 to 10 workers for Oban job processing

resource "aws_appautoscaling_target" "etl_worker" {
  max_capacity       = 10  # Maximum workers for parallel processing
  min_capacity       = 0   # Scale to zero when no jobs
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.etl_worker.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    Name = "ETL Worker Auto-Scaling Target"
    Environment = var.environment
    Purpose = "Oban job processing scaling"
  }
}

# Optional: Auto-scaling policy based on CPU utilization
# This can automatically scale workers if CPU gets too high
resource "aws_appautoscaling_policy" "etl_worker_scale_up" {
  name               = "${var.cluster_name}-etl-worker-scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.etl_worker.resource_id
  scalable_dimension = aws_appautoscaling_target.etl_worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.etl_worker.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown               = 300  # 5 minutes
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 2  # Add 2 workers when CPU is high
    }
  }
}

resource "aws_appautoscaling_policy" "etl_worker_scale_down" {
  name               = "${var.cluster_name}-etl-worker-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.etl_worker.resource_id
  scalable_dimension = aws_appautoscaling_target.etl_worker.scalable_dimension
  service_namespace  = aws_appautoscaling_target.etl_worker.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown               = 600  # 10 minutes
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1  # Remove 1 worker when CPU is low
    }
  }
}

# CloudWatch Alarms for automatic scaling (optional)
resource "aws_cloudwatch_metric_alarm" "etl_worker_cpu_high" {
  alarm_name          = "${var.cluster_name}-etl-worker-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors ECS service CPU utilization for ETL worker"

  dimensions = {
    ServiceName = aws_ecs_service.etl_worker.name
    ClusterName = aws_ecs_cluster.this.name
  }

  alarm_actions = [aws_appautoscaling_policy.etl_worker_scale_up.arn]

  tags = {
    Name = "ETL Worker CPU High"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_metric_alarm" "etl_worker_cpu_low" {
  alarm_name          = "${var.cluster_name}-etl-worker-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "This metric monitors ECS service CPU utilization for ETL worker"

  dimensions = {
    ServiceName = aws_ecs_service.etl_worker.name
    ClusterName = aws_ecs_cluster.this.name
  }

  alarm_actions = [aws_appautoscaling_policy.etl_worker_scale_down.arn]

  tags = {
    Name = "ETL Worker CPU Low"
    Environment = var.environment
  }
}