defmodule FileScanner.Scanner do
  require Logger

  def run(prefix \\ "") do
    bucket = Application.fetch_env!(:common, :s3_bucket)

    Logger.info("Scanning bucket: #{bucket}")

    s3 = Application.get_env(:common, :s3, Common.S3)

    s3.list_keys(bucket, prefix: prefix)
    |> Flow.from_enumerable(max_demand: 5, stages: 2)
    |> Flow.map(fn key ->
      Logger.info("Enqueing file: #{key}")

      %{"file" => key}
      |> Oban.Job.new(queue: :etl_files, worker: "EtlPipeline.Workers.EtlFileJob")
      |> then(&Oban.insert!(Common.FileScannerOban, &1))

      Logger.info("File enqueued: #{key}")
      :ok
    end)
    |> Flow.run()
  end
end
