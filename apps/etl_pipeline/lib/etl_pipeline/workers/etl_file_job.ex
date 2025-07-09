defmodule EtlPipeline.Workers.EtlFileJob do
  use Oban.Worker, queue: :etl_files, max_attempts: 5
  alias Oban.Job
  alias EtlPipeline.Etl

  require Logger

  @dest_s3_key Application.compile_env(:etl_pipeline, :dest_s3_key, "config/dest.csv")

  @impl true
  def perform(%Job{args: %{"file" => file_path}}) do
    Logger.info("🚀 [ETLFileJob] Starting ETL for file: #{file_path}")

    samples =
      file_path
      |> Etl.FileStreamer.stream_s3_bucket()
      |> Etl.Sampler.sample(10)

    samples
    |> Flow.from_enumerable(max_demand: 10, stages: 4)
    |> Flow.map(&Etl.Enricher.enrich(&1, @dest_s3_key))
    |> Flow.map(&Etl.Validator.validate/1)
    |> Flow.filter(& &1)
    |> Flow.run()
  end
end
