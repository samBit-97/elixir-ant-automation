import Config

# Runtime configuration - evaluated when the release starts, not when it's built
# This allows ECS environment variables to be used properly

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

