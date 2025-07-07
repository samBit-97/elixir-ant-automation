defmodule Mix.Tasks.FileScanner.Run do
  use Mix.Task
  require Logger

  @shortdoc "Runs the ETL scanner"

  def run(args) do
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
