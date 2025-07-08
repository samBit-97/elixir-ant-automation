defmodule Mix.Tasks.FileScanner.Run do
  use Mix.Task
  require Logger

  @shortdoc "Runs the ETL scanner"

  def run(args) do
    # Set APP_TYPE to file_scanner mode
    System.put_env("APP_TYPE", "file_scanner")
    
    # start apps
    Application.load(:common)
    Application.ensure_all_started(:common)
    Application.load(:file_scanner)
    Application.ensure_all_started(:file_scanner)

    prefix =
      case args do
        [p] -> p
        _ -> ""
      end

    Logger.info("Running ETLScanner.Scanner.run/1 with prefix: #{prefix}")

    result = FileScanner.Scanner.run(prefix)
    Logger.info("Scanner completed with result: #{inspect(result)}")
    Logger.info("File scanning complete. Files have been enqueued for processing.")
  end
end
