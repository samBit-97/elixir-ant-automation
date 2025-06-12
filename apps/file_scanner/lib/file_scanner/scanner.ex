defmodule FileScanner.Scanner do
  require Logger

  @s3 Application.compile_env(:file_scanner, :s3)

  def run(prefix \\ "") do
    bucket = @s3.bucket()

    Logger.info("Scanning bucket: #{bucket}")

    @s3.list_keys(bucket, prefix: prefix)
    |> Flow.from_enumerable()
    |> Flow.map(fn key ->
      Logger.info("Enqueing file: #{key}")

      EtlPipeline.Workers.EtlFileJob.new(%{"file" => key})
      |> Oban.insert!()

      Logger.info("File enqueued: #{key}")

      :ok
    end)
  end
end
