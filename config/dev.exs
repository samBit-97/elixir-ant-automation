import Config

# LocalStack configuration for development
config :ex_aws,
  access_key_id: "test",
  secret_access_key: "test",
  region: "us-east-1"

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 4566,
  region: "us-east-1",
  force_path_style: true

config :ex_aws, :dynamodb,
  scheme: "http://",
  host: "localhost",
  port: 4566,
  region: "us-east-1"

# Development defaults
config :common, s3_bucket: "tnt-pipeline-etl-files-dev"
config :common, :dynamodb_table, "tnt_pipeline_test_results_dev"

config :common, Common.Repo,
  database: "etl_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool_size: 20
