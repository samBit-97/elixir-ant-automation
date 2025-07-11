defmodule Etl.Workers.EtlFileJob do
  @moduledoc """
  ETL processing job that enriches, validates data and creates persist jobs.

  Part of the 2-queue architecture:
  Scanner -> etl_files -> persist_results
  """

  use Oban.Worker, queue: :etl_files, max_attempts: 5
  alias Oban.Job
  alias Etl.{FileStreamer, Sampler, Enricher, Validator}

  require Logger

  @impl true
  def perform(%Job{args: %{"file" => file_path}}) do
    Logger.info("⚙️ [ETLFileJob] Starting ETL for file: #{file_path}")

    try do
      # Process file through ETL pipeline
      processed_results =
        file_path
        |> FileStreamer.stream_s3_bucket()
        |> Sampler.sample(10)
        |> Flow.from_enumerable(max_demand: 10, stages: 4)
        |> Flow.map(&Enricher.enrich(&1))
        |> Flow.map(&Validator.validate/1)
        |> Flow.filter(& &1)
        |> Enum.to_list()

      if length(processed_results) > 0 do
        # Create persist job for DynamoDB batch write using clean syntax
        %{
          "file" => file_path,
          "results" => processed_results,
          "processed_at" => DateTime.utc_now() |> DateTime.to_iso8601()
        }
        |> Etl.Workers.PersistResultsJob.new()
        |> Oban.insert!()

        Logger.info(
          "✅ [ETLFileJob] Created persist job for #{length(processed_results)} results from: #{file_path}"
        )

        # Optional: Create dashboard update job for real-time UI
        %{
          "file" => file_path,
          "count" => length(processed_results),
          "status" => "completed"
        }
        |> Dashboard.Workers.DashboardUpdateJob.new()
        |> Oban.insert!()

        :ok
      else
        Logger.warning("⚠️ [ETLFileJob] No valid results from file: #{file_path}")
        :ok
      end
    rescue
      error ->
        Logger.error("❌ [ETLFileJob] Error processing #{file_path}: #{inspect(error)}")
        {:error, "ETL processing failed: #{inspect(error)}"}
    end
  end
end
