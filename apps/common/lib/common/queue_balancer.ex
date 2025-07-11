defmodule Common.QueueBalancer do
  @moduledoc """
  Queue metrics publisher for 4-node LibCluster architecture.

  Designed for 4-node LibCluster architecture:
  - No worker redistribution (role-based queue assignment)
  - Publishes metrics to CloudWatch for ECS auto-scaling
  - Smart idle detection for scale-to-zero capabilities
  - File scanner runs as one-shot task (no persistent instances)
  """

  use GenServer
  require Logger

  # Check every 30 seconds
  @check_interval 30_000

  # Consider node idle after 3 minutes of no activity
  @idle_threshold 3 * 60 * 1000

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    node_role = System.get_env("NODE_ROLE", "balanced")

    Logger.info("🎯 [QueueBalancer] Starting metrics publisher for NODE_ROLE: #{node_role}")

    # Schedule first check
    Process.send_after(self(), :rebalance, @check_interval)

    {:ok,
     %{
       node_role: node_role,
       last_activity: System.system_time(:millisecond),
       last_job_processed: System.system_time(:millisecond)
     }}
  end

  @impl true
  def handle_info(:rebalance, state) do
    new_state = perform_metrics_publishing(state)

    # Schedule next check
    Process.send_after(self(), :rebalance, @check_interval)

    {:noreply, new_state}
  end

  ## Private Functions

  defp perform_metrics_publishing(state) do
    try do
      queue_stats = get_queue_stats()
      current_queues = get_current_oban_queues()

      # Update activity tracking
      new_state = update_activity_tracking(state, queue_stats)

      # Check if this dedicated node is idle for scaling decisions
      node_idle = is_dedicated_node_idle?(queue_stats, new_state)

      # Publish CloudWatch metrics for ECS auto-scaling
      publish_metrics(queue_stats, current_queues, node_idle)

      new_state
    rescue
      error ->
        Logger.error("❌ [QueueBalancer] Error: #{inspect(error)}")
        state
    end
  end

  defp get_queue_stats do
    try do
      # Query database directly for job counts by queue
      import Ecto.Query

      query =
        from(j in "oban_jobs",
          where: j.state in ["available", "executing"],
          group_by: [j.queue, j.state],
          select: {j.queue, j.state, count()}
        )

      results = Common.Repo.all(query)

      # Convert to nested map structure: %{queue_name => %{available: count, executing: count}}
      Enum.reduce(results, %{}, fn {queue, state, count}, acc ->
        queue_stats = Map.get(acc, queue, %{available: 0, executing: 0})
        updated_stats = Map.put(queue_stats, String.to_atom(state), count)
        Map.put(acc, queue, updated_stats)
      end)
    rescue
      error ->
        Logger.warning("⚠️ [QueueBalancer] Could not get queue stats: #{inspect(error)}")
        %{}
    end
  end

  defp get_current_oban_queues do
    try do
      # Get current Oban queue configuration
      Oban.config()
      |> Map.get(:queues, [])
      |> Map.new()
    rescue
      _ -> %{}
    end
  end

  defp is_dedicated_node_idle?(queue_stats, state) do
    # LibCluster node idle detection:
    # 1. No jobs in this node's dedicated queues
    # 2. No jobs processed in last 3 minutes
    # 3. All nodes can scale to zero (file_scanner runs as one-shot task)

    node_role = state.node_role

    # All nodes can scale to 0 (file_scanner is one-shot task)
    dedicated_jobs = get_dedicated_queue_jobs(queue_stats, node_role)
    no_recent_activity = no_recent_activity?(state.last_job_processed)

    dedicated_jobs == 0 && no_recent_activity
  end

  defp get_dedicated_queue_jobs(queue_stats, node_role) do
    # Get job count for this node's dedicated queues
    queue_names =
      case node_role do
        "file_scanner" -> []  # One-shot task, no queue processing
        "etl_worker" -> ["etl_files"]
        "balanced" -> ["persist_results", "dashboard_updates", "monitoring"]
        _ -> []
      end

    # Sum jobs across all queues for this node role
    Enum.reduce(queue_names, 0, fn queue_name, acc ->
      stats = Map.get(queue_stats, queue_name, %{})
      available = Map.get(stats, :available, 0)
      executing = Map.get(stats, :executing, 0)
      acc + available + executing
    end)
  end

  defp calculate_total_jobs(queue_stats) do
    Enum.reduce(queue_stats, 0, fn {_queue, stats}, acc ->
      available = Map.get(stats, :available, 0)
      executing = Map.get(stats, :executing, 0)
      acc + available + executing
    end)
  end

  defp no_recent_activity?(last_job_time) do
    current_time = System.system_time(:millisecond)
    current_time - last_job_time > @idle_threshold
  end

  defp update_activity_tracking(state, queue_stats) do
    current_time = System.system_time(:millisecond)

    # Check if there are any jobs currently executing
    has_executing_jobs =
      Enum.any?(queue_stats, fn {_queue, stats} ->
        Map.get(stats, :executing, 0) > 0
      end)

    # Update last_job_processed if there are executing jobs
    new_last_job_processed =
      if has_executing_jobs do
        current_time
      else
        state.last_job_processed
      end

    %{state | last_activity: current_time, last_job_processed: new_last_job_processed}
  end

  defp publish_metrics(queue_stats, current_queues, node_idle) do
    try do
      total_jobs = calculate_total_jobs(queue_stats)
      total_workers = calculate_total_workers(current_queues)

      # Publish key metrics to CloudWatch
      metrics = [
        # Queue-specific metrics
        {queue_job_metrics(queue_stats), "QueueJobs"},
        {queue_worker_metrics(current_queues), "QueueWorkers"},

        # Node-level metrics
        {"TotalJobs", total_jobs, "Count"},
        {"TotalWorkers", total_workers, "Count"},
        {"NodeIdle", if(node_idle, do: 1, else: 0), "Count"}
      ]

      # Send metrics to CloudWatch (async)
      Task.start(fn ->
        send_cloudwatch_metrics(metrics)
      end)

      # Log metrics for debugging
      Logger.debug(
        "📊 [QueueBalancer] Metrics - Jobs: #{total_jobs}, Workers: #{total_workers}, Idle: #{node_idle}"
      )
    rescue
      error ->
        Logger.warning("⚠️ [QueueBalancer] Failed to publish metrics: #{inspect(error)}")
    end
  end

  defp queue_job_metrics(queue_stats) do
    Enum.flat_map(queue_stats, fn {queue, stats} ->
      [
        {"#{queue}_Available", Map.get(stats, :available, 0), "Count"},
        {"#{queue}_Executing", Map.get(stats, :executing, 0), "Count"}
      ]
    end)
  end

  defp queue_worker_metrics(current_queues) do
    Enum.map(current_queues, fn {queue, workers} ->
      {"#{queue}_Workers", workers, "Count"}
    end)
  end

  defp calculate_total_workers(current_queues) do
    Enum.reduce(current_queues, 0, fn {_queue, workers}, acc ->
      acc + workers
    end)
  end

  defp send_cloudwatch_metrics(metrics) do
    try do
      # Use Common.CloudWatch or ExAws.CloudWatch to send metrics
      namespace = "TntPipeline/QueueBalancer"
      node_role = System.get_env("NODE_ROLE", "balanced")

      # Flatten all metrics into a single list
      all_metrics =
        Enum.flat_map(metrics, fn
          {metric_list, _category} when is_list(metric_list) -> metric_list
          {name, value, unit} -> [{name, value, unit}]
        end)

      # Group metrics into batches of 20 (CloudWatch limit)
      all_metrics
      |> Enum.chunk_every(20)
      |> Enum.each(fn batch ->
        cloudwatch_data =
          Enum.map(batch, fn {name, value, unit} ->
            %{
              metric_name: name,
              value: value,
              unit: unit,
              dimensions: [
                %{name: "NodeRole", value: node_role},
                %{name: "NodeId", value: Node.self() |> to_string()}
              ]
            }
          end)

        # Send to CloudWatch (implement based on your AWS setup)
        case Application.get_env(:common, :cloudwatch_client) do
          nil ->
            Logger.debug("📊 [QueueBalancer] CloudWatch client not configured, skipping metrics")

          client ->
            client.put_metric_data(namespace, cloudwatch_data)
        end
      end)
    rescue
      error ->
        Logger.warning("⚠️ [QueueBalancer] CloudWatch metrics failed: #{inspect(error)}")
    end
  end
end
