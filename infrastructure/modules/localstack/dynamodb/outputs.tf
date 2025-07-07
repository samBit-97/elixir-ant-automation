output "table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.test_results_local.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table"
  value       = aws_dynamodb_table.test_results_local.arn
}

output "stream_arn" {
  description = "ARN of the DynamoDB stream"
  value       = aws_dynamodb_table.test_results_local.stream_arn
}

output "stream_label" {
  description = "Label of the DynamoDB stream"
  value       = aws_dynamodb_table.test_results_local.stream_label
}