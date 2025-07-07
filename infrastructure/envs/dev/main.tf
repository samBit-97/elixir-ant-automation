# LocalStack provider configuration for development
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style          = true

  endpoints {
    dynamodb = "http://localhost:4566"
    s3       = "http://localhost:4566"
    iam      = "http://localhost:4566"
    logs     = "http://localhost:4566"
  }
}

# DynamoDB table using LocalStack module
module "dynamodb" {
  source = "../../modules/localstack/dynamodb"

  table_name = var.table_name
  tags = {
    Name        = var.table_name
    Environment = "dev"
    Project     = "tnt-pipeline"
  }
}


# S3 bucket for file storage (LocalStack Community compatible)
module "s3" {
  source = "../../modules/localstack/s3"

  bucket_name = var.s3_bucket_name
  environment = "dev"
  tags = {
    Name        = var.s3_bucket_name
    Environment = "dev"
    Project     = "tnt-pipeline"
  }
}

