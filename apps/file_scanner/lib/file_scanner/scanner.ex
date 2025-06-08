defmodule FileScanner.Scanner do
  alias Oban.Job
  alias Common.S3
  require Logger

  def run(prefix \\ "") do
    bucket = S3.bucket()

    Logger.info("Scanning bucket: #{bucket}")

    ExAws.S3.list_objects_v2(bucket, prefix: prefix)
    |> ExAws.stream!()
    |> Stream.map(& &1.key)
    |> Flow.from_enumerable()
    |> Flow.map(fn key ->
      Logger.info("Enqueing file: #{key}")

      %Job{
        queue: :etl_files,
        worker: EtlPipeline.Workers.EtlFileJob,
        args: %{"file" => key}
      }
      |> Oban.insert!()

      Logger.info("File enqueued: #{key}")

      :ok
    end)
  end
end
