# DynamoDB table for ETL test results with streams enabled
resource "aws_dynamodb_table" "test_results" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "test_id"
  range_key      = "timestamp"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "test_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "file_key"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "shipper_id"
    type = "S"
  }

  # GSI for querying by file_key
  global_secondary_index {
    name     = "file_key-timestamp-index"
    hash_key = "file_key"
    range_key = "timestamp"
    projection_type = "ALL"
  }

  # GSI for querying by status
  global_secondary_index {
    name     = "status-timestamp-index"
    hash_key = "status"
    range_key = "timestamp"
    projection_type = "ALL"
  }

  # GSI for querying by shipper_id
  global_secondary_index {
    name     = "shipper_id-timestamp-index"
    hash_key = "shipper_id"
    range_key = "timestamp"
    projection_type = "ALL"
  }

  # TTL for automatic cleanup after 30 days
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = var.tags
}

# IAM role for DynamoDB access
resource "aws_iam_role" "dynamodb_role" {
  name = "${var.table_name}-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for DynamoDB operations
resource "aws_iam_role_policy" "dynamodb_policy" {
  name = "${var.table_name}-dynamodb-policy"
  role = aws_iam_role.dynamodb_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams"
        ]
        Resource = [
          aws_dynamodb_table.test_results.arn,
          "${aws_dynamodb_table.test_results.arn}/*",
          aws_dynamodb_table.test_results.stream_arn
        ]
      }
    ]
  })
}