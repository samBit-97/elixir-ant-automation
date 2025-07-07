# LocalStack DynamoDB table for development
resource "aws_dynamodb_table" "test_results_local" {
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

  # TTL for automatic cleanup after 30 days (LocalStack supports this)
  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = var.tags
}