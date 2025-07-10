defmodule ScannerTest do
  use ExUnit.Case
  use Oban.Testing, repo: Common.Repo

  import Mox
  import Mock

  defmock(S3Mock, for: Common.S3.S3Behaviour)

  setup :verify_on_exit!

  setup do
    Application.put_env(:common, :s3, S3Mock)
    Application.put_env(:common, :s3_bucket, "tnt-pipeline-etl-files-test")
    :ok
  end

  test "scanner enqueues file jobs" do
    S3Mock
    |> expect(:list_keys, fn "tnt-pipeline-etl-files-test", [prefix: ""] ->
      ["file1.txt", "file2.txt", "file3.txt", "file4.txt"]
    end)

    # Mock job insertion instead of actually running it
    with_mock Oban, [:passthrough],
      insert!: fn oban_instance, changeset ->
        assert oban_instance == Common.FileScannerOban
        assert changeset.changes.queue == "etl_files"
        assert changeset.changes.worker == "EtlPipeline.Workers.EtlFileJob"
        # return a fake job
        %Oban.Job{id: 1}
      end do
      FileScanner.Scanner.run()

      # Verify Oban.insert! was called for all files (should be called 4 times)
      assert_called(Oban.insert!(Common.FileScannerOban, :_))
    end
  end
end
