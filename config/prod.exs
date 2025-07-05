import Config

# Production AWS S3 configuration
config :ex_aws, :s3,
  region: System.get_env("AWS_REGION", "us-east-1"),
  scheme: "https://",
  host: "s3.amazonaws.com"

# Production database configuration
config :etl_pipeline, EtlPipeline.Repo,
  database: System.get_env("DB_NAME", "etl_rds"),
  username: System.get_env("DB_USERNAME") || raise("DB_USERNAME not set"),
  password: System.get_env("DB_PASSWORD") || raise("DB_PASSWORD not set"),
  hostname: System.get_env("RDS_HOSTNAME") || raise("RDS_HOSTNAME not set"),
  port: String.to_integer(System.get_env("DB_PORT", "5432")),
  pool_size: String.to_integer(System.get_env("DB_POOL_SIZE", "20"))

# Logging configuration for production
config :logger, level: :info

# Runtime configuration for production
config :etl_pipeline, EtlPipeline.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: System.get_env("HOST"), port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"
