variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "tnt_pipeline_test_results"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "tnt-pipeline"
    Environment = "dev"
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}