defmodule EtlPipeline.Workers.EtlFileJob do
  use Oban.Worker, queue: :etl_files, max_attempts: 5
  alias Oban.Job
  alias EtlPipeline.Etl

  require Logger

  @impl true
  def perform(%Job{args: %{"file" => file_path}}) do
    Logger.info("🚀 [ETLFileJob] Starting ETL for file: #{file_path}")

    samples =
      file_path
      |> Etl.FileStreamer.stream()
      |> Etl.Sampler.sample(10)

    samples
    # continue Flow for parallel stages
    |> Flow.from_enumerable()
    |> Flow.map(&Etl.Enricher.enrich/1)
    |> Flow.map(&Etl.Validator.validate/1)
    |> Enum.map(&wrap_test_case(file_path, &1))
    |> Enum.each(&ETLPipeline.Repo.insert!/1)
  end

  defp wrap_test_case(file_path, test_case) do
  end
end
