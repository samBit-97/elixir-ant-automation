output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.test_results.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.test_results.arn
}

output "stream_arn" {
  description = "ARN of the DynamoDB stream"
  value       = aws_dynamodb_table.test_results.stream_arn
}

output "stream_label" {
  description = "Label of the DynamoDB stream"
  value       = aws_dynamodb_table.test_results.stream_label
}

output "dynamodb_role_arn" {
  description = "ARN of the IAM role for DynamoDB access"
  value       = aws_iam_role.dynamodb_role.arn
}