defmodule Common.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Configure Oban instances based on runtime environment
    oban_children = configure_oban_instances()

    children =
      [
        # Starts a worker by calling: Common.Worker.start_link(arg)
        # {Common.Worker, arg}
        Common.Repo
      ] ++ oban_children

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Common.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp configure_oban_instances do
    app_type = System.get_env("APP_TYPE", "etl_pipeline")

    require Logger
    Logger.info("🚀 [Common.Application] Configuring Oban instances for APP_TYPE: #{app_type}")

    config = case app_type do
          "file_scanner" ->
            # File scanner only needs Oban for job insertion (no queue processing)
            Logger.info("📂 [Common.Application] Starting FileScannerOban (insertion only)")

            [
              {Oban,
               [
                 name: Common.FileScannerOban,
                 repo: Common.Repo,
                 plugins: [Oban.Plugins.Pruner],
                 # No queues - insertion only
                 queues: []
               ]}
            ]

          "etl_pipeline" ->
            # ETL pipeline needs Oban for job processing with queues
            Logger.info("⚙️ [Common.Application] Starting EtlOban (with job processing)")

            [
              {Oban,
               [
                 name: Common.EtlOban,
                 repo: Common.Repo,
                 plugins: [Oban.Plugins.Pruner],
                 # Process jobs with 50 concurrent workers
                 queues: [etl_files: 50]
               ]}
            ]

          _ ->
            # Default: start both (for development/test environments)
            Logger.info("🔧 [Common.Application] Starting both Oban instances (development mode)")

            [
              {Oban,
               [
                 name: Common.FileScannerOban,
                 repo: Common.Repo,
                 plugins: [Oban.Plugins.Pruner],
                 queues: []
               ]},
              {Oban,
               [
                 name: Common.EtlOban,
                 repo: Common.Repo,
                 plugins: [Oban.Plugins.Pruner],
                 queues: [etl_files: 50]
               ]}
            ]
        end

    Logger.info("✅ [Common.Application] Oban configuration ready: #{length(config)} instance(s)")
    config
  end
end
