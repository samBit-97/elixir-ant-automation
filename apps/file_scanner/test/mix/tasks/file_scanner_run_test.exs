defmodule Mix.Tasks.FileScanner.RunTest do
  use ExUnit.Case, async: true
  import Mock

  alias Mix.Tasks.FileScanner.Run

  describe "run/1" do
    test "starts applications and runs scanner with no args" do
      with_mock Application, [:passthrough],
        load: fn _ -> :ok end,
        ensure_all_started: fn _ -> {:ok, []} end do
        with_mock Process, [:passthrough], sleep: fn _ -> :ok end do
          with_mock FileScanner.Scanner, [:passthrough], run: fn _ -> :ok end do
            Run.run([])

            assert_called Application.load(:common)
            assert_called Application.load(:file_scanner)
            assert_called Application.ensure_all_started(:common)
            assert_called Application.ensure_all_started(:file_scanner)
            assert_called Process.sleep(2000)
            assert_called FileScanner.Scanner.run("")
          end
        end
      end
    end

    test "runs scanner with prefix argument" do
      with_mock Application, [:passthrough],
        load: fn _ -> :ok end,
        ensure_all_started: fn _ -> {:ok, []} end do
        with_mock Process, [:passthrough], sleep: fn _ -> :ok end do
          with_mock FileScanner.Scanner, [:passthrough], run: fn _ -> :ok end do
            Run.run(["test_prefix"])

            assert_called FileScanner.Scanner.run("test_prefix")
          end
        end
      end
    end

    test "uses empty prefix for multiple arguments" do
      with_mock Application, [:passthrough],
        load: fn _ -> :ok end,
        ensure_all_started: fn _ -> {:ok, []} end do
        with_mock Process, [:passthrough], sleep: fn _ -> :ok end do
          with_mock FileScanner.Scanner, [:passthrough], run: fn _ -> :ok end do
            Run.run(["arg1", "arg2", "arg3"])

            assert_called FileScanner.Scanner.run("")
          end
        end
      end
    end

    test "logs scanner start and completion" do
      with_mock Application, [:passthrough],
        load: fn _ -> :ok end,
        ensure_all_started: fn _ -> {:ok, []} end do
        with_mock Process, [:passthrough], sleep: fn _ -> :ok end do
          with_mock FileScanner.Scanner, [:passthrough], run: fn _ -> {:ok, "scan result"} end do
            with_mock Logger, [:passthrough], info: fn _ -> :ok end do
              Run.run(["test"])

              assert_called Logger.info("Running ETLScanner.Scanner.run/1 with prefix: test")
              assert_called Logger.info("Scanner completed with result: {:ok, \"scan result\"}")
              assert_called Logger.info("File scanning complete. Files have been enqueued for processing.")
            end
          end
        end
      end
    end
  end
end