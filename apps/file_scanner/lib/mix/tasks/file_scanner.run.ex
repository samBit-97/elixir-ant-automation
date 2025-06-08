defmodule Mix.Tasks.FileScanner.Run do
  use Mix.Task
  require Logger

  @shortdoc "Runs the ETL scanner"

  def run(args) do
    # start apps
    Mix.Task.run("app.start")

    prefix =
      case args do
        [p] -> p
        _ -> ""
      end

    Logger.info("Running ETLScanner.Scanner.run/1 with prefix: #{prefix}")

    FileScanner.Scanner.run(prefix)
  end
end
