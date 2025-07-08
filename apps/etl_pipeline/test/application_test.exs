defmodule EtlPipeline.ApplicationTest do
  use ExUnit.Case, async: true
  import Mock

  alias EtlPipeline.Application

  describe "start/2" do
    test "starts the application with required children" do
      with_mock Supervisor, [:passthrough],
        start_link: fn _children, _opts -> {:ok, self()} end do
        Application.start(:normal, [])

        assert_called(
          Supervisor.start_link(:_, strategy: :one_for_one, name: EtlPipeline.Supervisor)
        )
      end
    end

    test "does not include Oban in children (moved to Common)" do
      with_mock Supervisor, [:passthrough],
        start_link: fn children, _opts ->
          # Verify Oban is NOT in the children list (it's now in Common.Application)
          refute Enum.any?(children, fn child ->
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

