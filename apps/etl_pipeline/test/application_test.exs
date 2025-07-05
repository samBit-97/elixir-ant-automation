defmodule EtlPipeline.ApplicationTest do
  use ExUnit.Case, async: true
  import Mock

  alias EtlPipeline.Application

  describe "start/2" do
    test "starts the application with required children" do
      with_mock Supervisor, [:passthrough], start_link: fn children, opts -> {:ok, self()} end do
        Application.start(:normal, [])
        
        assert_called Supervisor.start_link(:_, 
          [strategy: :one_for_one, name: EtlPipeline.Supervisor])
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
        Application.start(:normal, [])
      end
    end
  end
end