defmodule FileScanner.Scanner do
  require Logger

  def run(prefix \\ "") do
    bucket = Application.fetch_env!(:common, :s3_bucket)
    app_type = System.get_env("APP_TYPE", "unknown")

    Logger.info("Scanning bucket: #{bucket}")
    Logger.info("APP_TYPE: #{app_type}")
    
    # Check if Oban instance is available
    case Oban.config(Common.FileScannerOban) do
      %Oban.Config{} = config ->
        Logger.info("Oban instance Common.FileScannerOban is running: #{inspect(config.name)}")
      nil ->
        Logger.error("Oban instance Common.FileScannerOban is not available!")
        raise "Oban instance Common.FileScannerOban is not running"
    end

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
