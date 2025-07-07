variable "cluster_name" {
  description = "Name of the ECS Cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS Fargate tasks will run"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ECS Fargate tasks"
  type        = list(string)
}

variable "rds_hostname" {
  description = "RDS endpoint hostname"
  type        = string
}

variable "rds_credentials_secret_arn" {
  type        = string
  description = "ARN of the RDS credentials secret"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket for ETL files"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  default     = "prod"
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table for test results"
  type        = string
  default     = "tnt_pipeline_test_results"
}
