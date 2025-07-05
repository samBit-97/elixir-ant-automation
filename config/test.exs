import Config

config :common, s3_bucket: "tnt-automation-test"
config :common, :s3, Common.S3Mock

config :common, Common.Repo,
  database: "etl_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5433,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :etl_pipeline, Oban,
  repo: Common.Repo,
  testing: :manual,
  name: EtlPipelineTestOban

config :file_scanner, Oban,
  repo: Common.Repo,
  testing: :manual,
  name: FileScannerTestOban

config :etl_pipeline,
  api_url: "http://localhost:8083",
  whm_client_id: "test_client",
  auth_token: "test_token",
  default_first_name: "Test",
  default_last_name: "User",
  default_contact: "Test Contact",
  default_phone: "555-0123",
  hold_at_address1: "123 Test St",
  hold_at_city: "Test City",
  hold_at_contact: "Test Contact",
  hold_at_company: "Test Company",
  hold_at_country: "USA",
  hold_at_postal_code: "12345",
  hold_at_state: "TX",
  hold_at_email: "test@example.com",
  hold_at_phone: "555-0123",
  return_address1: "456 Return St",
  return_city: "Return City",
  return_country: "USA",
  return_postal_code: "67890",
  return_state: "CA",
  printer_name: "test_printer",
  printer_ip: "127.0.0.1"
