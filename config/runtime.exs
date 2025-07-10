import Config

# Runtime configuration - evaluated when the release starts, not when it's built
# This allows ECS environment variables to be used properly

# API Configuration for ETL Pipeline (applies to all environments)
config :etl_pipeline,
  api_url: System.get_env("API_URL", "http://localhost:8083"),
  whm_client_id: System.get_env("WHM_CLIENT_ID", "whm_client_id"),
  auth_token: System.get_env("AUTH_TOKEN", "auth_token"),
  default_first_name: System.get_env("DEFAULT_FIRST_NAME", "Customer"),
  default_last_name: System.get_env("DEFAULT_LAST_NAME", "Name"),
  default_contact: System.get_env("DEFAULT_CONTACT", "Customer Service"),
  default_phone: System.get_env("DEFAULT_PHONE", "000-000-0000"),
  hold_at_address1: System.get_env("HOLD_AT_ADDRESS1", "123 Main St"),
  hold_at_city: System.get_env("HOLD_AT_CITY", "Your City"),
  hold_at_contact: System.get_env("HOLD_AT_CONTACT", "Contact Name"),
  hold_at_company: System.get_env("HOLD_AT_COMPANY", "Your Company"),
  hold_at_country: System.get_env("HOLD_AT_COUNTRY", "USA"),
  hold_at_postal_code: System.get_env("HOLD_AT_POSTAL_CODE", "12345"),
  hold_at_state: System.get_env("HOLD_AT_STATE", "ST"),
  hold_at_email: System.get_env("HOLD_AT_EMAIL", "contact@company.com"),
  hold_at_phone: System.get_env("HOLD_AT_PHONE", "555-123-4567"),
  return_address1: System.get_env("RETURN_ADDRESS1", "456 Return St"),
  return_city: System.get_env("RETURN_CITY", "Return City"),
  return_country: System.get_env("RETURN_COUNTRY", "USA"),
  return_postal_code: System.get_env("RETURN_POSTAL_CODE", "67890"),
  return_state: System.get_env("RETURN_STATE", "RT"),
  printer_name: System.get_env("PRINTER_NAME", "production_printer"),
  printer_ip: System.get_env("PRINTER_IP", "192.168.1.100")

if config_env() == :prod do
  # Production database configuration for Common.Repo (used by Oban and file_scanner)
  config :common, Common.Repo,
    database: System.get_env("DB_NAME", "etl_rds"),
    username: System.get_env("DB_USERNAME") || raise("DB_USERNAME not set"),
    password: System.get_env("DB_PASSWORD") || raise("DB_PASSWORD not set"),
    hostname: System.get_env("RDS_HOSTNAME") || raise("RDS_HOSTNAME not set"),
    port: String.to_integer(System.get_env("DB_PORT", "5432")),
    pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "10")),
    ssl: true,
    ssl_opts: [verify: :verify_none]

  # S3 bucket configuration for production
  config :common, s3_bucket: System.get_env("S3_BUCKET", "tnt-pipeline-etl-files-prod")
  
  # DynamoDB table configuration for production
  config :common, :dynamodb_table, System.get_env("DYNAMODB_TABLE", "tnt_pipeline_test_results_prod")
  
  # ETL Pipeline configuration for production
  config :etl_pipeline, :dest_s3_key, System.get_env("DEST_S3_KEY", "config/dest.csv")

  # AWS configuration - use ECS task role for credentials
  config :ex_aws,
    access_key_id: :instance_role,
    secret_access_key: :instance_role,
    security_token: :instance_role,
    region: System.get_env("AWS_REGION", "us-east-1")

  config :ex_aws, :s3,
    region: System.get_env("AWS_REGION", "us-east-1"),
    scheme: "https://",
    host: "s3.amazonaws.com"
end

# Configuration for all non-production environments
# Set defaults if environment variables are not provided
config :common, s3_bucket: System.get_env("S3_BUCKET", "tnt-pipeline-etl-files-dev")
config :common, :dynamodb_table, System.get_env("DYNAMODB_TABLE", "tnt_pipeline_test_results_dev")
config :etl_pipeline, :dest_s3_key, System.get_env("DEST_S3_KEY", "config/dest.csv")
