import Config

config :etl_pipeline, EtlPipeline.Repo,
  database: "etl_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5433,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :common, Common.S3, s3_bucket: "tnt-automation-test"

config :file_scanner, :s3, Common.S3Mock

config :etl_pipeline, Oban,
  repo: EtlPipeline.Repo,
  testing: :manual
