import Config

# LocalStack configuration for development
config :ex_aws, :s3,
  scheme: System.get_env("S3_SCHEME", "http://"),
  host: System.get_env("S3_HOST", "localhost"),
  port: String.to_integer(System.get_env("S3_PORT", "4566")),
  region: System.get_env("AWS_REGION", "us-east-1"),
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID", "test"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY", "test"),
  force_path_style: true

config :common, Common.Repo,
  database: System.get_env("DB_NAME", "etl_dev"),
  username: System.get_env("DB_USERNAME", "postgres"),
  password: System.get_env("DB_PASSWORD", "postgres"),
  hostname: System.get_env("DB_HOSTNAME", "localhost"),
  port: String.to_integer(System.get_env("DB_PORT", "5432")),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "20"))

