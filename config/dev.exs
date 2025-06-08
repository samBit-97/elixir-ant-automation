import Config

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 4566,
  region: "us-east-1",
  access_key_id: "test",
  secret_access_key: "test",
  force_path_style: true
