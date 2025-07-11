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

# Note: Task definitions are now centralized in task_definitions.tf
# This file focuses on LibCluster infrastructure components

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

