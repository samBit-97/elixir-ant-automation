variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
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