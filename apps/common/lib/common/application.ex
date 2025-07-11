defmodule Common.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Configure clustering and unified Oban instance
    cluster_children = configure_clustering()
    oban_children = configure_unified_oban()

    # Database connection
    children =
      ([
         Common.Repo
       ] ++
         cluster_children ++
         oban_children ++
         [
           # Smart queue balancer (only in production for clustering)
           if(Mix.env() == :prod, do: Common.QueueBalancer, else: nil)
         ])
      |> Enum.filter(& &1)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Common.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp configure_clustering do
    # Only configure clustering in production
    if Mix.env() == :prod do
      cluster_config = [
        strategy: Cluster.Strategy.DNSPoll,
        config: [
          query: System.get_env("ECS_SERVICE_NAME", "tnt-pipeline") <> ".tnt-pipeline.local",
          node_basename: "tnt_pipeline",
          polling_interval: 10_000
        ]
      ]

      require Logger
      Logger.info("🌐 [Common.Application] Configuring LibCluster with DNS polling")

      [
        {Cluster.Supervisor, [cluster_config, [name: TntPipeline.ClusterSupervisor]]}
      ]
    else
      []
    end
  end

  defp configure_unified_oban do
    # Use NODE_ROLE for role-based queue configuration
    node_role = System.get_env("NODE_ROLE", "balanced")

    require Logger
    Logger.info("🚀 [Common.Application] Configuring unified Oban for NODE_ROLE: #{node_role}")

    # Configure queues based on dedicated node roles (4-node architecture)
    queues =
      case node_role do
        "etl_worker" ->
          # NodeA: Dedicated ETL processing (auto-scaling 0-10)
          Logger.info(
            "⚙️ [Common.Application] Starting etl_worker role - dedicated etl_files queue"
          )

          [etl_files: 50]

        "persist_worker" ->
          # NodeB: Dedicated DynamoDB batch writes (auto-scaling 0-8)
          Logger.info(
            "💾 [Common.Application] Starting persist_worker role - dedicated persist_results queue"
          )

          [persist_results: 20]

        "dashboard_worker" ->
          # NodeC: Dedicated dashboard updates (scale to 0 when idle)
          Logger.info(
            "📊 [Common.Application] Starting dashboard_worker role - dedicated dashboard_updates queue"
          )

          [dashboard_updates: 10]

        "monitoring" ->
          # NodeD: Always-on monitoring (fixed 1-2 instances)
          Logger.info(
            "🔍 [Common.Application] Starting monitoring role - dedicated monitoring queue"
          )

          [monitoring: 5]

        "file_scanner" ->
          # Legacy coordinator role for backward compatibility
          Logger.info(
            "📂 [Common.Application] Starting file_scanner role - runs scanner directly to etl_files"
          )

          [etl_files: 10, monitoring: 2]

        _ ->
          # Default: development mode with all queues
          Logger.info("🔧 [Common.Application] Starting development mode with all queues")

          [
            etl_files: 10,
            persist_results: 5,
            dashboard_updates: 2,
            monitoring: 1
          ]
      end

    # Single unified Oban instance with clustering support
    oban_config = [
      repo: Common.Repo,
      plugins: [
        Oban.Plugins.Pruner,
        # shares load info across nodes
        Oban.Plugins.Gossip,
        Oban.Plugins.Lifeline,
        {Oban.Plugins.Cron, crontab: []}
      ],
      queues: queues
    ]

    Logger.info(
      "✅ [Common.Application] Unified Oban configuration ready with #{length(queues)} queues"
    )

    Logger.info("📊 [Common.Application] Queue configuration: #{inspect(queues)}")

    [
      {Oban, oban_config}
    ]
  end
end
