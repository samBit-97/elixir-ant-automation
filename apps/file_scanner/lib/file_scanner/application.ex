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
      {Oban, Application.fetch_env!(:file_scanner, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FileScanner.Supervisor]
    
    result = Supervisor.start_link(children, opts)
    
    # Auto-run scanner if environment variable is set
    if System.get_env("AUTO_RUN_SCANNER") == "true" do
      Task.start(fn -> 
        # Add a small delay to ensure all applications are started
        Process.sleep(1000)
        FileScanner.Scanner.run()
      end)
    end
    
    result
  end
end
