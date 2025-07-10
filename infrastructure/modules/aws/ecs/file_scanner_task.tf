# Dedicated ECS task definition for file_scanner.run
resource "aws_ecs_task_definition" "file_scanner" {
  family                   = "${var.cluster_name}-file-scanner"
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
      name      = "file-scanner",
      image     = "445567085614.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-file-scanner:latest",
      essential = true,

      # Use startup script with proper APP_TYPE setting
      command = ["/app/run_scanner.sh"],

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
        { name = "APP_TYPE", value = "file_scanner" },
        { name = "S3_BUCKET", value = var.s3_bucket_name },
        { name = "RDS_HOSTNAME", value = var.rds_hostname },
        { name = "DYNAMODB_TABLE", value = var.dynamodb_table_name },
        { name = "AWS_DEFAULT_REGION", value = "us-east-1" },
        { name = "DB_NAME", value = "etl_rds" },
        { name = "DB_PORT", value = "5432" },
        { name = "AWS_REGION", value = "us-east-1" }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/file-scanner",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# CloudWatch log group for file scanner
resource "aws_cloudwatch_log_group" "file_scanner" {
  name              = "/ecs/file-scanner"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Application = "file-scanner"
  }
}

