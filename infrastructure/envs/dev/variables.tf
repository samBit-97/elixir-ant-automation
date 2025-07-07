variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "tnt_pipeline_test_results_dev"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "tnt-pipeline-etl-files-dev"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}


