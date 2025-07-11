defmodule TntPipeline.Application do
  @moduledoc """
  Unified TNT Pipeline application that coordinates all domains.
  
  This replaces the separate file_scanner and etl_pipeline applications
  with a single monolith that uses LibCluster and smart queue balancing.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Common application starts automatically as a dependency
      # ETL-specific processes
      Etl.DestinationCache
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TntPipeline.Supervisor]
    Supervisor.start_link(children, opts)
  end
end