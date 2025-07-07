# ETL worker task definition for processing jobs
resource "aws_ecs_task_definition" "etl_worker" {
  family                   = "${var.cluster_name}-etl-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "etl-worker",
      image     = "445567085614.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-etl:latest",
      essential = true,
      
      # Run Oban worker to process jobs
      command = ["mix", "run", "--no-halt"],
      
      secrets = [
        {
          name      = "DB_USERNAME",
          valueFrom = "${var.rds_credentials_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD",
          valueFrom = "${var.rds_credentials_secret_arn}:password::"
        }
      ]
      environment = [
        { name = "MIX_ENV", value = "prod" },
        { name = "S3_BUCKET", value = var.s3_bucket_name },
        { name = "RDS_HOSTNAME", value = var.rds_hostname },
        { name = "DYNAMODB_TABLE", value = var.dynamodb_table_name },
        { name = "AWS_DEFAULT_REGION", value = "us-east-1" },
        { name = "DB_NAME", value = "etl_rds" },
        { name = "DB_PORT", value = "5432" }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/etl-worker",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# CloudWatch log group for ETL workers
resource "aws_cloudwatch_log_group" "etl_worker" {
  name              = "/ecs/etl-worker"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Application = "etl-worker"
  }
}

