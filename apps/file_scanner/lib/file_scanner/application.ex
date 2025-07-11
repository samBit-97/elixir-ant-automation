defmodule FileScanner.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: FileScanner.Worker.start_link(arg)
      # {FileScanner.Worker, arg}
      # Oban is now started in Common.Application
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FileScanner.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
