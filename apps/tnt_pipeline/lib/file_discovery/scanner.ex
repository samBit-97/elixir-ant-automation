defmodule FileDiscovery.Scanner do
  @moduledoc """
  S3 file discovery scanner that directly creates ETL jobs.

  Optimized flow: Scanner validates files -> directly enqueues to etl_files
  Eliminates the intermediate file_discovery queue for better performance.
  """

  require Logger

  def run(prefix \\ "") do
    bucket = Application.fetch_env!(:common, :s3_bucket)
    node_role = System.get_env("NODE_ROLE", "balanced")

    Logger.info("📂 [FileDiscovery.Scanner] Scanning bucket: #{bucket}")
    Logger.info("🎯 [FileDiscovery.Scanner] NODE_ROLE: #{node_role}")

    # Check if unified Oban instance is available
    case Oban.config() do
      %Oban.Config{} = config ->
        Logger.info(
          "✅ [FileDiscovery.Scanner] Unified Oban instance running: #{inspect(config.name)}"
        )

      nil ->
        Logger.error("❌ [FileDiscovery.Scanner] Unified Oban instance is not available!")
        raise "Unified Oban instance is not running"
    end

    s3 = Application.get_env(:common, :s3, Common.S3)

    # Create ETL jobs directly for valid files (skip file_discovery queue)
    file_count =
      s3.list_keys(bucket, prefix: prefix)
      |> Flow.from_enumerable(max_demand: 5, stages: 2)
      |> Flow.map(fn key ->
        Logger.info("📁 [FileDiscovery.Scanner] Validating file: #{key}")

        # Validate file and directly create ETL job if valid
        if valid_file?(key, bucket) do
          %{"file" => key}
          |> Etl.Workers.EtlFileJob.new()
          |> Oban.insert!()

          Logger.info("✅ [FileDiscovery.Scanner] ETL job created for: #{key}")
          1
        else
          Logger.warning("⚠️ [FileDiscovery.Scanner] Skipping invalid file: #{key}")
          0
        end
      end)
      |> Flow.run()
      |> Enum.sum()

    Logger.info("🎉 [FileDiscovery.Scanner] Completed scanning - #{file_count} ETL jobs created")

    file_count
  end

  defp valid_file?(file_path, _bucket) do
    # File validation logic (moved from FileDiscoveryJob)
    cond do
      String.ends_with?(file_path, ".csv") ->
        Logger.warning("⚠️ [FileDiscovery.Scanner] Not a CSV file: #{file_path}")
        false

      String.starts_with?(Path.basename(file_path), ".") ->
        Logger.warning("⚠️ [FileDiscovery.Scanner] Hidden file: #{file_path}")
        false

      true ->
        # File is valid CSV and not hidden
        true
    end
  end
end
