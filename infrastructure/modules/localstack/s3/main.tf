# Simplified S3 bucket for LocalStack Community edition
resource "aws_s3_bucket" "etl_files" {
  bucket = var.bucket_name

  tags = var.tags
}

# No event notifications - simplified for manual processing