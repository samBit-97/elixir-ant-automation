defmodule FileScanner.ApplicationTest do
  use ExUnit.Case, async: true
  import Mock

  alias FileScanner.Application

  describe "start/2" do
    test "starts the application with required children" do
      with_mock Supervisor, [:passthrough], start_link: fn children, opts -> {:ok, self()} end do
        with_mock System, [:passthrough], get_env: fn "AUTO_RUN_SCANNER" -> nil end do
          Application.start(:normal, [])
          
          assert_called Supervisor.start_link(:_, 
            [strategy: :one_for_one, name: FileScanner.Supervisor])
        end
      end
    end

    test "includes Oban in children" do
      with_mock Supervisor, [:passthrough], start_link: fn children, _opts -> 
        # Verify Oban is in the children list
        assert Enum.any?(children, fn child ->
          case child do
            {Oban, _config} -> true
            _ -> false
          end
        end)
        {:ok, self()}
      end do
        with_mock System, [:passthrough], get_env: fn "AUTO_RUN_SCANNER" -> nil end do
          Application.start(:normal, [])
        end
      end
    end

    test "auto-runs scanner when AUTO_RUN_SCANNER is true" do
      with_mock Supervisor, [:passthrough], start_link: fn _children, _opts -> {:ok, self()} end do
        with_mock System, [:passthrough], get_env: fn "AUTO_RUN_SCANNER" -> "true" end do
          with_mock Task, [:passthrough], start: fn _fun -> {:ok, self()} end do
            Application.start(:normal, [])
            
            assert_called Task.start(:_)
          end
        end
      end
    end

    test "does not auto-run scanner when AUTO_RUN_SCANNER is not true" do
      with_mock Supervisor, [:passthrough], start_link: fn _children, _opts -> {:ok, self()} end do
        with_mock System, [:passthrough], get_env: fn "AUTO_RUN_SCANNER" -> "false" end do
          with_mock Task, [:passthrough], start: fn _fun -> {:ok, self()} end do
            Application.start(:normal, [])
            
            assert_not_called Task.start(:_)
          end
        end
      end
    end
  end
end