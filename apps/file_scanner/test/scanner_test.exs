defmodule ScannerTest do
  use ExUnit.Case
  use Oban.Testing, repo: EtlPipeline.Repo

  test "scanner enqueues file jobs" do
    Oban.Testing.with_testing_mode(:manual, fn ->
      FileScanner.Scanner.run()
      |> Flow.run()

      assert_enqueued(worker: EtlPipeline.Workers.EtlFileJob, args: %{"file" => "file1.txt"})
      assert_enqueued(worker: EtlPipeline.Workers.EtlFileJob, args: %{"file" => "file2.txt"})
      assert_enqueued(worker: EtlPipeline.Workers.EtlFileJob, args: %{"file" => "file3.txt"})
      assert_enqueued(worker: EtlPipeline.Workers.EtlFileJob, args: %{"file" => "file4.txt"})
    end)
  end
end
