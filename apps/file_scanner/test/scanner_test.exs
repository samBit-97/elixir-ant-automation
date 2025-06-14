defmodule ScannerTest do
  use ExUnit.Case
  use Oban.Testing, repo: EtlPipeline.Repo

  import Mox

  defmock(S3Mock, for: Common.S3.S3Behaviour)

  setup :verify_on_exit!

  setup do
    Application.put_env(:common, :s3, S3Mock)
    :ok
  end

  test "scanner enqueues file jobs" do
    S3Mock
    |> expect(:list_keys, fn "tnt-automation-test", _ ->
      ["file1.txt", "file2.txt", "file3.txt", "file4.txt"]
    end)

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
