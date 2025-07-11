defmodule Dashboard.Workers.DashboardUpdateJob do
  @moduledoc """
  Real-time dashboard update job for UI notifications.

  Handles:
  - File processing completion notifications
  - Real-time metrics updates
  - WebSocket broadcasts to connected clients
  """

  use Oban.Worker, queue: :dashboard_updates, max_attempts: 2
  alias Oban.Job

  require Logger

  @impl true
  def perform(%Job{args: %{"file" => file_path, "count" => count, "status" => status}}) do
    Logger.info(
      "📊 [DashboardUpdateJob] Processing dashboard update for #{file_path}: #{count} results, status: #{status}"
    )

    try do
      # Broadcast update to connected dashboard clients
      broadcast_update(%{
        file: file_path,
        count: count,
        status: status,
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      })

      # Update internal metrics (if you have a metrics store)
      update_processing_metrics(file_path, count, status)

      Logger.info(
        "✅ [DashboardUpdateJob] Successfully broadcast dashboard update for: #{file_path}"
      )

      :ok
    rescue
      error ->
        Logger.error(
          "❌ [DashboardUpdateJob] Error processing dashboard update: #{inspect(error)}"
        )

        {:error, "Dashboard update failed: #{inspect(error)}"}
    end
  end

  defp broadcast_update(update_data) do
    # If you're using Phoenix PubSub for real-time updates
    if Code.ensure_loaded?(Phoenix.PubSub) do
      Phoenix.PubSub.broadcast(
        TntPipeline.PubSub,
        "dashboard:updates",
        {:file_processed, update_data}
      )

      Logger.debug("📡 [DashboardUpdateJob] Broadcast via PubSub: #{inspect(update_data)}")
    else
      Logger.debug("📊 [DashboardUpdateJob] PubSub not available, skipping broadcast")
    end
  end

  defp update_processing_metrics(file_path, count, status) do
    # Update any internal metrics storage
    # This could be ETS tables, GenServer state, or another data store
    Logger.debug(
      "📈 [DashboardUpdateJob] Updating metrics - File: #{file_path}, Count: #{count}, Status: #{status}"
    )

    # Example: Update ETS table if you have one
    if :ets.info(:processing_metrics) != :undefined do
      :ets.insert(:processing_metrics, {file_path, count, status, DateTime.utc_now()})
    end

    :ok
  end
end

