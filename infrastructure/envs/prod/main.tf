provider "aws" {
  region = "us-east-1"
}

resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "prod/rds/credentials-v2"
  description = "RDS credentials for production"
}

resource "aws_secretsmanager_secret_version" "rds_credentials_version" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id

  secret_string = jsonencode({
    username = var.rds_username
    password = var.rds_password
  })
}

data "aws_secretsmanager_secret_version" "rds_secrets" {
  secret_id  = aws_secretsmanager_secret.rds_credentials.id
  depends_on = [aws_secretsmanager_secret_version.rds_credentials_version]
}

module "vpc" {
  source              = "../../modules/aws/vpc"
  name                = "etl-vpc"
  vpc_cidr            = "10.0.0.0/16"
  public_subnet_count = 2
  availability_zones  = ["us-east-1a", "us-east-1b"]
}

locals {
  rds_secret = jsondecode(data.aws_secretsmanager_secret_version.rds_secrets.secret_string)
}

module "rds" {
  source                 = "../../modules/aws/rds"
  name                   = "etl-prod"
  allocated_storage      = 20
  instance_class         = "db.t3.micro"
  db_name                = "etl_rds"
  db_username            = local.rds_secret.username
  db_password            = local.rds_secret.password
  subnet_ids             = module.vpc.public_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = true
  tags = {
    Name        = "etl-rds"
    Environment = "prod"
  }
}

module "ecs_cluster" {
  source                     = "../../modules/aws/ecs"
  cluster_name               = "etl-cluster-prod"
  subnet_ids                 = module.vpc.public_subnet_ids
  vpc_id                     = module.vpc.vpc_id
  rds_hostname               = module.rds.db_address
  rds_credentials_secret_arn = aws_secretsmanager_secret.rds_credentials.arn
  s3_bucket_name             = var.s3_bucket_name
  dynamodb_table_name        = var.dynamodb_table_name
  environment                = "prod"
  # api_url is now generated dynamically within the ECS module
  whm_client_id              = var.whm_client_id
  auth_token                 = var.auth_token
}

# DynamoDB table for production
module "dynamodb" {
  source = "../../modules/aws/dynamodb"

  table_name  = var.dynamodb_table_name
  environment = "prod"
  tags = {
    Name        = var.dynamodb_table_name
    Environment = "prod"
    Project     = "tnt-pipeline"
  }
}


# S3 bucket for file storage in production
module "s3" {
  source = "../../modules/aws/s3"

  bucket_name = var.s3_bucket_name
  environment = "prod"
  tags = {
    Name        = var.s3_bucket_name
    Environment = "prod"
    Project     = "tnt-pipeline"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow Postgres"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Only for testing. Change to trusted IPs in prod.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Output the Go API URL for use in terraform.tfvars
output "go_api_url" {
  description = "URL of the Go API service via ALB"
  value       = module.ecs_cluster.go_api_url
}

output "go_api_alb_dns_name" {
  description = "DNS name of the Go API ALB"
  value       = module.ecs_cluster.go_api_alb_dns_name
}

# ECS networking outputs for start-etl-pipeline-task.sh script
output "subnet_id" {
  description = "First subnet ID for ECS tasks"
  value       = module.ecs_cluster.subnet_id
}

output "subnet_ids" {
  description = "All subnet IDs for ECS tasks"
  value       = module.ecs_cluster.subnet_ids
}

output "ecs_security_group_id" {
  description = "Security group ID for ECS Fargate tasks"
  value       = module.ecs_cluster.ecs_security_group_id
}

output "fargate_security_group_id" {
  description = "Security group ID for ECS Fargate tasks"
  value       = module.ecs_cluster.fargate_security_group_id
}

output "cluster_name" {
  description = "Name of the ECS Cluster"
  value       = module.ecs_cluster.cluster_name
}

output "etl_task_definition_arn" {
  description = "ARN of the ETL worker task definition"
  value       = module.ecs_cluster.etl_task_definition_arn
}
