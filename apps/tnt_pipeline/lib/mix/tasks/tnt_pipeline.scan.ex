defmodule Mix.Tasks.TntPipeline.Scan do
  @moduledoc """
  Mix task for scanning S3 bucket and enqueueing file discovery jobs.

  ## Usage

      mix tnt_pipeline.scan
      mix tnt_pipeline.scan "folder/subfolder"

  ## Examples

      # Scan all files in the bucket
      mix tnt_pipeline.scan
      
      # Scan files with specific prefix
      mix tnt_pipeline.scan "data/2024/"
  """

  use Mix.Task
  require Logger

  @shortdoc "Scan S3 bucket and enqueue file discovery jobs"

  def run(args) do
    Mix.Task.run("app.start")

    prefix =
      case args do
        [prefix] ->
          prefix

        [] ->
          ""

        _ ->
          Mix.shell().error("Usage: mix tnt_pipeline.scan [prefix]")
          exit(:normal)
      end

    Logger.info("🚀 [TntPipeline.Scan] Starting S3 scan with prefix: '#{prefix}'")

    file_count = FileDiscovery.Scanner.run(prefix)

    Logger.info("✅ [TntPipeline.Scan] Completed: #{file_count} files discovered and enqueued")
  end
end

