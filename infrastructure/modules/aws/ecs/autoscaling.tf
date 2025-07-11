# ECS Auto-Scaling Configuration for TNT Pipeline
# Enables dynamic scaling based on CloudWatch metrics from QueueBalancer

#########################################
# Auto-Scaling Targets
#########################################

# ETL Workers Auto-Scaling Target (Nodes 2-3)
resource "aws_appautoscaling_target" "etl_workers" {
  max_capacity       = 10
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.etl_workers.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    Name        = "TNT Pipeline ETL Workers Auto-Scaling"
    Environment = var.environment
    NodeRole    = "etl_worker"
  }
}

# Balanced Workers Auto-Scaling Target (Nodes 4-5)
resource "aws_appautoscaling_target" "balanced_workers" {
  max_capacity       = 8
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.this.name}/${aws_ecs_service.balanced_workers.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    Name        = "TNT Pipeline Balanced Workers Auto-Scaling"
    Environment = var.environment
    NodeRole    = "balanced"
  }
}

#########################################
# Auto-Scaling Policies
#########################################

# ETL Workers - Scale Up Policy
resource "aws_appautoscaling_policy" "etl_workers_scale_up" {
  name               = "etl-workers-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.etl_workers.resource_id
  scalable_dimension = aws_appautoscaling_target.etl_workers.scalable_dimension
  service_namespace  = aws_appautoscaling_target.etl_workers.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 50.0
    scale_in_cooldown  = 300 # 5 minutes
    scale_out_cooldown = 60  # 1 minute

    customized_metric_specification {
      metric_name = "etl_files_Available"
      namespace   = "TntPipeline/QueueBalancer"
      statistic   = "Average"
    }
  }
}

# ETL Workers - Scale Down Policy (based on idle nodes)
resource "aws_appautoscaling_policy" "etl_workers_scale_down" {
  name               = "etl-workers-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.etl_workers.resource_id
  scalable_dimension = aws_appautoscaling_target.etl_workers.scalable_dimension
  service_namespace  = aws_appautoscaling_target.etl_workers.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 600 # 10 minutes
    metric_aggregation_type = "Maximum"

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_upper_bound = 0
    }
  }
}

# Balanced Workers - Scale Up Policy
resource "aws_appautoscaling_policy" "balanced_workers_scale_up" {
  name               = "balanced-workers-scale-up"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.balanced_workers.resource_id
  scalable_dimension = aws_appautoscaling_target.balanced_workers.scalable_dimension
  service_namespace  = aws_appautoscaling_target.balanced_workers.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 25.0
    scale_in_cooldown  = 300 # 5 minutes
    scale_out_cooldown = 60  # 1 minute

    customized_metric_specification {
      metric_name = "persist_results_Available"
      namespace   = "TntPipeline/QueueBalancer"
      statistic   = "Average"
      dimensions = {
        NodeRole = "balanced"
      }
    }
  }
}

# Balanced Workers - Scale Down Policy
resource "aws_appautoscaling_policy" "balanced_workers_scale_down" {
  name               = "balanced-workers-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.balanced_workers.resource_id
  scalable_dimension = aws_appautoscaling_target.balanced_workers.scalable_dimension
  service_namespace  = aws_appautoscaling_target.balanced_workers.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 600 # 10 minutes
    metric_aggregation_type = "Maximum"

    step_adjustment {
      scaling_adjustment          = -1
      metric_interval_upper_bound = 0
    }
  }
}

#########################################
# CloudWatch Alarms
#########################################

# ETL Workers - High Queue Depth Alarm
resource "aws_cloudwatch_metric_alarm" "etl_high_queue_depth" {
  alarm_name          = "tnt-pipeline-etl-high-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "etl_files_Available"
  namespace           = "TntPipeline/QueueBalancer"
  period              = "60"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "This metric monitors etl_files queue depth"
  alarm_actions       = [aws_appautoscaling_policy.etl_workers_scale_up.arn]

  dimensions = {
    NodeRole = "etl_worker"
  }

  tags = {
    Name        = "TNT Pipeline ETL High Queue Depth"
    Environment = var.environment
  }
}

# ETL Workers - Idle Nodes Alarm
resource "aws_cloudwatch_metric_alarm" "etl_idle_nodes" {
  alarm_name          = "tnt-pipeline-etl-idle-nodes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "NodeIdle"
  namespace           = "TntPipeline/QueueBalancer"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors idle ETL nodes for scale-down"
  alarm_actions       = [aws_appautoscaling_policy.etl_workers_scale_down.arn]

  dimensions = {
    NodeRole = "etl_worker"
  }

  tags = {
    Name        = "TNT Pipeline ETL Idle Nodes"
    Environment = var.environment
  }
}

# Balanced Workers - High Persist Results Jobs Alarm
resource "aws_cloudwatch_metric_alarm" "balanced_high_jobs" {
  alarm_name          = "tnt-pipeline-balanced-high-jobs"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "persist_results_Available"
  namespace           = "TntPipeline/QueueBalancer"
  period              = "60"
  statistic           = "Average"
  threshold           = "25"
  alarm_description   = "This metric monitors persist_results queue for balanced workers"
  alarm_actions       = [aws_appautoscaling_policy.balanced_workers_scale_up.arn]

  dimensions = {
    NodeRole = "balanced"
  }

  tags = {
    Name        = "TNT Pipeline Balanced High Jobs"
    Environment = var.environment
  }
}

# Balanced Workers - Idle Nodes Alarm
resource "aws_cloudwatch_metric_alarm" "balanced_idle_nodes" {
  alarm_name          = "tnt-pipeline-balanced-idle-nodes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "NodeIdle"
  namespace           = "TntPipeline/QueueBalancer"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors idle balanced nodes for scale-down"
  alarm_actions       = [aws_appautoscaling_policy.balanced_workers_scale_down.arn]

  dimensions = {
    NodeRole = "balanced"
  }

  tags = {
    Name        = "TNT Pipeline Balanced Idle Nodes"
    Environment = var.environment
  }
}

#########################################
# IAM Role for Auto-Scaling
#########################################

# IAM Role for ECS Auto-Scaling
resource "aws_iam_role" "ecs_autoscaling_role" {
  name = "tnt-pipeline-ecs-autoscaling-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "TNT Pipeline ECS Auto-Scaling Role"
    Environment = var.environment
  }
}

# IAM Policy for ECS Auto-Scaling
resource "aws_iam_role_policy" "ecs_autoscaling_policy" {
  name = "tnt-pipeline-ecs-autoscaling-policy"
  role = aws_iam_role.ecs_autoscaling_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms"
        ]
        Resource = "*"
      }
    ]
  })
}

# Additional IAM permissions for task execution to publish CloudWatch metrics
resource "aws_iam_role_policy_attachment" "task_cloudwatch_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom policy for CloudWatch metrics publishing
resource "aws_iam_role_policy" "cloudwatch_metrics_policy" {
  name = "tnt-pipeline-cloudwatch-metrics-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

