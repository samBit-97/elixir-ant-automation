import Config

config :common, s3_bucket: "tnt-automation-test"
config :common, :s3, Common.S3Mock

config :etl_pipeline, EtlPipeline.Repo,
  database: "etl_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5433,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :etl_pipeline, Oban,
  repo: EtlPipeline.Repo,
  testing: :manual
