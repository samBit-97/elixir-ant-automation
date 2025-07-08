defmodule EtlPipeline.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: EtlPipeline.Worker.start_link(arg)
      # {EtlPipeline.Worker, arg}
      # Oban will be started in Common.Application since it uses Common.Repo
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EtlPipeline.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
