# LibCluster setup for 5-node TNT Pipeline cluster

# Cluster secret for Erlang distribution
resource "aws_secretsmanager_secret" "cluster_secret" {
  name        = "${var.cluster_name}/cluster-secret"
  description = "Erlang cluster secret for LibCluster"

  tags = {
    Environment = var.environment
    Application = "tnt-pipeline-cluster"
  }
}

resource "aws_secretsmanager_secret_version" "cluster_secret" {
  secret_id = aws_secretsmanager_secret.cluster_secret.id
  secret_string = jsonencode({
    cookie = random_password.cluster_cookie.result
  })
}

resource "random_password" "cluster_cookie" {
  length  = 32
  special = true
}

# AWS Cloud Map service discovery namespace
resource "aws_service_discovery_private_dns_namespace" "tnt_pipeline" {
  name        = "tnt-pipeline.local"
  description = "Service discovery namespace for TNT Pipeline cluster"
  vpc         = var.vpc_id

  tags = {
    Name        = "TNT Pipeline Service Discovery"
    Environment = var.environment
  }
}

# Service discovery service for cluster nodes
resource "aws_service_discovery_service" "tnt_pipeline" {
  name = "tnt-pipeline"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.tnt_pipeline.id

    dns_records {
      ttl  = 60
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name        = "TNT Pipeline Service"
    Environment = var.environment
  }
}

# Enhanced security group for clustering
resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-cluster-"
  description = "Security group for TNT Pipeline cluster nodes"
  vpc_id      = var.vpc_id

  # Application health check port
  ingress {
    description = "Health Check"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # EPMD (Erlang Port Mapper Daemon)
  ingress {
    description = "EPMD"
    from_port   = 4369
    to_port     = 4369
    protocol    = "tcp"
    self        = true
  }

  # Erlang distribution port range
  ingress {
    description = "Erlang Distribution"
    from_port   = 9100
    to_port     = 9155
    protocol    = "tcp"
    self        = true
  }

  # External API access (for Go API)
  ingress {
    description = "External API"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # All outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.cluster_name}-cluster-sg"
    Environment = var.environment
  }
}

# 5-Node Cluster Task Definitions

# Node 1: Coordinator (file_scanner) - Always running
resource "aws_ecs_task_definition" "coordinator" {
  family                   = "${var.cluster_name}-coordinator"
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
      name      = "coordinator",
      image     = "445567085614.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-etl:latest",
      essential = true,

      command = ["./bin/etl_pipeline", "start"],

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
        { name = "RELEASE_COOKIE", value = "${CLUSTER_SECRET}" },
        { name = "ECS_CLUSTER_NAME", value = var.cluster_name },
        { name = "ECS_SERVICE_NAME", value = "coordinator" },
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
          awslogs-group         = "/ecs/coordinator",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Nodes 2-3: ETL Workers (on-demand)
resource "aws_ecs_task_definition" "etl_worker_cluster" {
  family                   = "${var.cluster_name}-etl-worker-cluster"
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
      name      = "etl-worker-cluster",
      image     = "445567085614.dkr.ecr.us-east-1.amazonaws.com/tnt-pipeline-etl:latest",
      essential = true,

      command = ["./bin/etl_pipeline", "start"],

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
        { name = "RELEASE_COOKIE", value = "${CLUSTER_SECRET}" },
        { name = "ECS_CLUSTER_NAME", value = var.cluster_name },
        { name = "ECS_SERVICE_NAME", value = "etl-worker" },
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
          awslogs-group         = "/ecs/etl-worker-cluster",
          awslogs-region        = "us-east-1",
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Nodes 4-5: Balanced Workers (on-demand)
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

      command = ["./bin/etl_pipeline", "start"],

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
        { name = "RELEASE_COOKIE", value = "${CLUSTER_SECRET}" },
        { name = "ECS_CLUSTER_NAME", value = var.cluster_name },
        { name = "ECS_SERVICE_NAME", value = "balanced-worker" },
        { name = "S3_BUCKET", value = var.s3_bucket_name },
        { name = "RDS_HOSTNAME", value = var.rds_hostname },
        { name = "DYNAMODB_TABLE", value = var.dynamodb_table_name },
        { name = "AWS_DEFAULT_REGION", value = "us-east-1" },
        { name = "DB_NAME", value = "etl_rds" },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_POOL_SIZE", value = "3" },
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

# CloudWatch log groups for cluster nodes
resource "aws_cloudwatch_log_group" "coordinator" {
  name              = "/ecs/coordinator"
  retention_in_days = 7
  tags = {
    Environment = var.environment
    Application = "coordinator"
  }
}

resource "aws_cloudwatch_log_group" "etl_worker_cluster" {
  name              = "/ecs/etl-worker-cluster"
  retention_in_days = 7
  tags = {
    Environment = var.environment
    Application = "etl-worker-cluster"
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

# Enhanced IAM role for cluster tasks
resource "aws_iam_role" "cluster_task_role" {
  name = "${var.cluster_name}-cluster-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = var.environment
    Application = "tnt-pipeline-cluster"
  }
}

# Enhanced permissions for clustering
resource "aws_iam_role_policy" "cluster_task_permissions" {
  name = "cluster-task-access"
  role = aws_iam_role.cluster_task_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = [
          var.rds_credentials_secret_arn,
          aws_secretsmanager_secret.cluster_secret.arn
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem"
        ],
        Resource = "arn:aws:dynamodb:*:*:table/${var.dynamodb_table_name}"
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:ListTasks",
          "ecs:DescribeTasks",
          "ecs:DescribeServices"
        ],
        Resource = "*",
        Condition = {
          StringEquals = {
            "ecs:cluster" = "arn:aws:ecs:us-east-1:*:cluster/${var.cluster_name}"
          }
        }
      },
      {
        Effect = "Allow",
        Action = [
          "servicediscovery:DiscoverInstances",
          "servicediscovery:GetInstancesHealthStatus"
        ],
        Resource = "*"
      }
    ]
  })
}

