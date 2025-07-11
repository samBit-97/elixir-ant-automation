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

# Static configuration (compile-time)
config :common, :s3, Common.S3
config :common, ecto_repos: [Common.Repo]
config :common, :http_client, Common.HttpoisonClient

config :common, Oban,
  repo: Common.Repo,
  plugins: [Oban.Plugins.Pruner],
  queues: [
    etl_files: 50
  ]

import_config "#{config_env()}.exs"
