# S3 bucket for ETL file processing
resource "aws_s3_bucket" "etl_files" {
  bucket = var.bucket_name

  tags = var.tags
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "etl_files_versioning" {
  bucket = aws_s3_bucket.etl_files.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "etl_files_pab" {
  bucket = aws_s3_bucket.etl_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# No event notifications - simplified for manual processing

