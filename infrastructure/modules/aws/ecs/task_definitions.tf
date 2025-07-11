# File Scanner task definition (Node 1 - Coordinator)
resource "aws_ecs_task_definition" "file_scanner" {
  family                   = "${var.cluster_name}-file-scanner"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.cluster_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "file-scanner",
      image     = "445567085614.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-etl:latest",
      essential = true,

      # Run scanner once and exit (one-shot execution)
      command = ["./bin/tnt_pipeline", "eval", "Mix.Tasks.TntPipeline.Scan.run([])"],

      secrets = [
        {
          name      = "DB_USERNAME",
          valueFrom = "${var.rds_credentials_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD",
          valueFrom = "${var.rds_credentials_secret_arn}:password::"
        },
        {
          name      = "CLUSTER_SECRET",
          valueFrom = "${aws_secretsmanager_secret.cluster_secret.arn}:cookie::"
        }
      ]
      environment = [
        { name = "MIX_ENV", value = "prod" },
        { name = "NODE_ROLE", value = "file_scanner" },
        { name = "RELEASE_DISTRIBUTION", value = "name" },
        { name = "LIBCLUSTER_STRATEGY", value = "ECS" },
        { name = "ECS_CLUSTER_NAME", value = var.cluster_name },
        { name = "ECS_SERVICE_NAME", value = "file-scanner" },
        { name = "SERVICE_DISCOVERY_NAMESPACE", value = "tnt-pipeline.local" },
        { name = "S3_BUCKET", value = var.s3_bucket_name },
        { name = "RDS_HOSTNAME", value = var.rds_hostname },
        { name = "DYNAMODB_TABLE", value = var.dynamodb_table_name },
        { name = "AWS_DEFAULT_REGION", value = "us-east-1" },
        { name = "DB_NAME", value = "etl_rds" },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_POOL_SIZE", value = "2" },
        { name = "DEST_S3_KEY", value = "config/dest.csv" },
        { name = "API_URL", value = "http://${aws_lb.go_api.dns_name}" },
        { name = "WHM_CLIENT_ID", value = var.whm_client_id },
        { name = "AUTH_TOKEN", value = var.auth_token }
      ],
      
      portMappings = [
        {
          containerPort = 4000
          protocol      = "tcp"
        },
        {
          containerPort = 4369
          protocol      = "tcp"
        }
      ],

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:4000/health || exit 1"],
        interval    = 30,
        timeout     = 5,
        retries     = 3,
        startPeriod = 60
      },

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

# ETL Worker task definition (Nodes 2-3)
resource "aws_ecs_task_definition" "etl_worker" {
  family                   = "${var.cluster_name}-etl-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.cluster_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "etl-worker",
      image     = "445567085614.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-etl:latest",
      essential = true,

      # Run as ETL worker node
      command = ["./bin/tnt_pipeline", "start"],

      secrets = [
        {
          name      = "DB_USERNAME",
          valueFrom = "${var.rds_credentials_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD",
          valueFrom = "${var.rds_credentials_secret_arn}:password::"
        },
        {
          name      = "CLUSTER_SECRET",
          valueFrom = "${aws_secretsmanager_secret.cluster_secret.arn}:cookie::"
        }
      ]
      environment = [
        { name = "MIX_ENV", value = "prod" },
        { name = "NODE_ROLE", value = "etl_worker" },
        { name = "RELEASE_DISTRIBUTION", value = "name" },
        { name = "LIBCLUSTER_STRATEGY", value = "ECS" },
        { name = "ECS_CLUSTER_NAME", value = var.cluster_name },
        { name = "ECS_SERVICE_NAME", value = "etl-workers" },
        { name = "SERVICE_DISCOVERY_NAMESPACE", value = "tnt-pipeline.local" },
        { name = "S3_BUCKET", value = var.s3_bucket_name },
        { name = "RDS_HOSTNAME", value = var.rds_hostname },
        { name = "DYNAMODB_TABLE", value = var.dynamodb_table_name },
        { name = "AWS_DEFAULT_REGION", value = "us-east-1" },
        { name = "DB_NAME", value = "etl_rds" },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_POOL_SIZE", value = "4" },
        { name = "DEST_S3_KEY", value = "config/dest.csv" },
        { name = "API_URL", value = "http://${aws_lb.go_api.dns_name}" },
        { name = "WHM_CLIENT_ID", value = var.whm_client_id },
        { name = "AUTH_TOKEN", value = var.auth_token }
      ],
      
      portMappings = [
        {
          containerPort = 4000
          protocol      = "tcp"
        },
        {
          containerPort = 4369
          protocol      = "tcp"
        }
      ],

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:4000/health || exit 1"],
        interval    = 30,
        timeout     = 5,
        retries     = 3,
        startPeriod = 60
      },

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

# Balanced Worker task definition (Nodes 4-5)
resource "aws_ecs_task_definition" "balanced_worker" {
  family                   = "${var.cluster_name}-balanced-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.cluster_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "balanced-worker",
      image     = "445567085614.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-etl:latest",
      essential = true,

      # Run as balanced worker node
      command = ["./bin/tnt_pipeline", "start"],

      secrets = [
        {
          name      = "DB_USERNAME",
          valueFrom = "${var.rds_credentials_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD",
          valueFrom = "${var.rds_credentials_secret_arn}:password::"
        },
        {
          name      = "CLUSTER_SECRET",
          valueFrom = "${aws_secretsmanager_secret.cluster_secret.arn}:cookie::"
        }
      ]
      environment = [
        { name = "MIX_ENV", value = "prod" },
        { name = "NODE_ROLE", value = "balanced" },
        { name = "RELEASE_DISTRIBUTION", value = "name" },
        { name = "LIBCLUSTER_STRATEGY", value = "ECS" },
        { name = "ECS_CLUSTER_NAME", value = var.cluster_name },
        { name = "ECS_SERVICE_NAME", value = "balanced-workers" },
        { name = "SERVICE_DISCOVERY_NAMESPACE", value = "tnt-pipeline.local" },
        { name = "S3_BUCKET", value = var.s3_bucket_name },
        { name = "RDS_HOSTNAME", value = var.rds_hostname },
        { name = "DYNAMODB_TABLE", value = var.dynamodb_table_name },
        { name = "AWS_DEFAULT_REGION", value = "us-east-1" },
        { name = "DB_NAME", value = "etl_rds" },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_POOL_SIZE", value = "4" },
        { name = "DEST_S3_KEY", value = "config/dest.csv" },
        { name = "API_URL", value = "http://${aws_lb.go_api.dns_name}" },
        { name = "WHM_CLIENT_ID", value = var.whm_client_id },
        { name = "AUTH_TOKEN", value = var.auth_token }
      ],
      
      portMappings = [
        {
          containerPort = 4000
          protocol      = "tcp"
        },
        {
          containerPort = 4369
          protocol      = "tcp"
        }
      ],

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:4000/health || exit 1"],
        interval    = 30,
        timeout     = 5,
        retries     = 3,
        startPeriod = 60
      },

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/balanced-worker",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# CloudWatch log groups for all node types
resource "aws_cloudwatch_log_group" "file_scanner" {
  name              = "/ecs/file-scanner"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Application = "file-scanner"
  }
}

resource "aws_cloudwatch_log_group" "etl_worker" {
  name              = "/ecs/etl-worker"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Application = "etl-worker"
  }
}

resource "aws_cloudwatch_log_group" "balanced_worker" {
  name              = "/ecs/balanced-worker"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Application = "balanced-worker"
  }
}

# Go API task definition for external API service
resource "aws_ecs_task_definition" "go_api" {
  family                   = "${var.cluster_name}-go-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.cluster_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "go-api",
      image     = "445567085614.dkr.ecr.us-east-1.amazonaws.com/mockclient:latest",
      essential = true,

      # Port mapping for API service
      portMappings = [
        {
          containerPort = 8081,
          protocol      = "tcp"
        }
      ],

      environment = [
        { name = "PORT", value = "8081" },
        { name = "ENV", value = "production" }
      ],

      # Health check for API endpoint
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8081/health || exit 1"],
        interval    = 30,
        timeout     = 5,
        retries     = 3,
        startPeriod = 60
      },

      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/go-api",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# CloudWatch log group for Go API
resource "aws_cloudwatch_log_group" "go_api" {
  name              = "/ecs/go-api"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Application = "go-api"
  }
}

# Database migration task definition - runs before cluster setup
resource "aws_ecs_task_definition" "db_migration" {
  family                   = "${var.cluster_name}-db-migration"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.cluster_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "db-migration",
      image     = "445567085614.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-etl:latest",
      essential = true,

      # Run database migrations
      command = ["./bin/etl_pipeline", "eval", "Common.Repo.start(); Ecto.Migrator.run(Common.Repo, :up, all: true)"],

      secrets = [
        {
          name      = "DB_USERNAME",
          valueFrom = "${var.rds_credentials_secret_arn}:username::"
        },
        {
          name      = "DB_PASSWORD",
          valueFrom = "${var.rds_credentials_secret_arn}:password::"
        },
        {
          name      = "CLUSTER_SECRET",
          valueFrom = "${aws_secretsmanager_secret.cluster_secret.arn}:cookie::"
        }
      ]
      environment = [
        { name = "MIX_ENV", value = "prod" },
        { name = "RDS_HOSTNAME", value = var.rds_hostname },
        { name = "DB_NAME", value = "etl_rds" },
        { name = "DB_PORT", value = "5432" },
        { name = "AWS_DEFAULT_REGION", value = "us-east-1" }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = "/ecs/db-migration",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# CloudWatch log group for database migration
resource "aws_cloudwatch_log_group" "db_migration" {
  name              = "/ecs/db-migration"
  retention_in_days = 7

  tags = {
    Environment = var.environment
    Application = "db-migration"
  }
}
