defmodule EtlPipeline.Repo do
  use Ecto.Repo,
    otp_app: :etl_pipeline,
    adapter: Ecto.Adapters.Postgres
end
