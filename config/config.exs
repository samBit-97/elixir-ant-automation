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

config :etl_pipeline, EtlPipeline.Repo,
  database: "etl_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :etl_pipeline, Oban,
  repo: EtlPipeline.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [
    etl_files: 50
  ]

config :etl_pipeline, ecto_repos: [EtlPipeline.Repo]

import_config "#{config_env()}.exs"
