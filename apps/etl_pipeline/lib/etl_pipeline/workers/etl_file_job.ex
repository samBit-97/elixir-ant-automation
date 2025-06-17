defmodule EtlPipeline.Workers.EtlFileJob do
  use Oban.Worker, queue: :etl_files, max_attempts: 5
  alias Oban.Job
  alias EtlPipeline.Etl

  require Logger

  @file_path Application.compile_env(:etl_pipeline, :file_path, "priv/tmp/dest.csv")

  @impl true
  def perform(%Job{args: %{"file" => file_path}}) do
    Logger.info("🚀 [ETLFileJob] Starting ETL for file: #{file_path}")

    samples =
      file_path
      |> Etl.FileStreamer.stream_s3_bucket()
      |> Etl.Sampler.sample(10)

    samples
    |> Flow.from_enumerable()
    |> Flow.map(&Etl.Enricher.enrich(&1, @file_path))
    |> Flow.map(&Etl.Validator.validate/1)
    |> Flow.filter(& &1)
    |> Enum.each(&EtlPipeline.Repo.insert!/1)
  end
end
