output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.etl_files.bucket
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.etl_files.arn
}

output "bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = aws_s3_bucket.etl_files.bucket_domain_name
}