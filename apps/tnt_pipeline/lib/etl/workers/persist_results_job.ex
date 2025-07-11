defmodule Etl.Workers.PersistResultsJob do
  @moduledoc """
  Efficient DynamoDB batch writer using existing Common.DynamoWriter.

  Features:
  - Leverages existing batch_write_test_results/1 function
  - Handles up to 25 items per batch (DynamoDB limit)
  - Automatic chunking for larger result sets
  """

  use Oban.Worker, queue: :persist_results, max_attempts: 3
  alias Oban.Job

  require Logger

  @impl true
  def perform(%Job{
        args: %{"file" => file_path, "results" => results, "processed_at" => _processed_at}
      }) do
    Logger.info(
      "💾 [PersistResultsJob] Starting DynamoDB batch write for #{length(results)} results from: #{file_path}"
    )

    try do
      # Use existing DynamoWriter batch method
      case Common.DynamoWriter.batch_write_test_results(results) do
        :ok ->
          Logger.info(
            "✅ [PersistResultsJob] Successfully persisted #{length(results)} results from: #{file_path}"
          )

          :ok

        {:error, reason} ->
          Logger.error(
            "❌ [PersistResultsJob] Failed to persist results from #{file_path}: #{inspect(reason)}"
          )

          {:error, "DynamoDB batch write failed: #{inspect(reason)}"}
      end
    rescue
      error ->
        Logger.error(
          "❌ [PersistResultsJob] Error persisting results from #{file_path}: #{inspect(error)}"
        )

        {:error, "DynamoDB batch write failed: #{inspect(error)}"}
    end
  end
end

