defmodule Common.Repo do
  use Ecto.Repo,
    otp_app: :common,
    adapter: Ecto.Adapters.Postgres
end