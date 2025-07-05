# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

config :common, s3_bucket: System.get_env("S3_BUCKET", "tnt-automation")
config :common, :s3, Common.S3

config :etl_pipeline, Oban,
  repo: Common.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [
    etl_files: 50
  ]

config :file_scanner, Oban,
  repo: Common.Repo,
  queues: [],
  plugins: []

config :common, ecto_repos: [Common.Repo]
config :etl_pipeline, :http_client, Common.HttpoisonClient

# API Configuration
config :etl_pipeline,
  api_url: System.get_env("API_URL"),
  whm_client_id: System.get_env("WHM_CLIENT_ID"),
  auth_token: System.get_env("AUTH_TOKEN"),
  # Default values for customer info
  default_first_name: System.get_env("DEFAULT_FIRST_NAME", "Customer"),
  default_last_name: System.get_env("DEFAULT_LAST_NAME", "Name"),
  default_contact: System.get_env("DEFAULT_CONTACT", "Customer Service"),
  default_phone: System.get_env("DEFAULT_PHONE", "000-000-0000"),
  # Hold at address configuration
  hold_at_address1: System.get_env("HOLD_AT_ADDRESS1"),
  hold_at_city: System.get_env("HOLD_AT_CITY"),
  hold_at_contact: System.get_env("HOLD_AT_CONTACT"),
  hold_at_company: System.get_env("HOLD_AT_COMPANY"),
  hold_at_country: System.get_env("HOLD_AT_COUNTRY", "USA"),
  hold_at_postal_code: System.get_env("HOLD_AT_POSTAL_CODE"),
  hold_at_state: System.get_env("HOLD_AT_STATE"),
  hold_at_email: System.get_env("HOLD_AT_EMAIL"),
  hold_at_phone: System.get_env("HOLD_AT_PHONE"),
  # Return address configuration
  return_address1: System.get_env("RETURN_ADDRESS1"),
  return_city: System.get_env("RETURN_CITY"),
  return_country: System.get_env("RETURN_COUNTRY", "USA"),
  return_postal_code: System.get_env("RETURN_POSTAL_CODE"),
  return_state: System.get_env("RETURN_STATE"),
  # Printer configuration
  printer_name: System.get_env("PRINTER_NAME", "default_printer"),
  printer_ip: System.get_env("PRINTER_IP", "127.0.0.1")

# AWS Configuration
config :ex_aws,
  access_key_id: System.get_env("AWS_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("AWS_SECRET_ACCESS_KEY"),
  region: System.get_env("AWS_REGION", "us-east-1")

import_config "#{config_env()}.exs"
