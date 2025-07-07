import Config

# Production compile-time configuration
# Runtime configuration is now in config/runtime.exs

# Logging configuration for production
config :logger, level: :info

# Runtime configuration for production
config :etl_pipeline, EtlPipeline.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: System.get_env("HOST"), port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json"
