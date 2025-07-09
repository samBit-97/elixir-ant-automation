variable "rds_username" {
  description = "Username for RDS"
  type        = string
}

variable "rds_password" {
  description = "Password for RDS"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "tnt_pipeline_test_results_prod"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "tnt-pipeline-etl-files-prod"
}

variable "api_url" {
  description = "External API URL for ETL pipeline"
  type        = string
  default     = "http://placeholder-api-url.com"
}

variable "whm_client_id" {
  description = "WHM Client ID for API authentication"
  type        = string
  default     = "placeholder-client-id"
}

variable "auth_token" {
  description = "Authentication token for API calls"
  type        = string
  sensitive   = true
  default     = "placeholder-auth-token"
}


