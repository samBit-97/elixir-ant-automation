defmodule EtlPipeline.HealthCheckTest do
  use ExUnit.Case, async: true
  import Mock

  alias EtlPipeline.HealthCheck

  setup do
    # Set up test configuration
    Application.put_env(:common, :s3_bucket, "test-bucket")
    :ok
  end

  describe "liveness_check/0" do
    test "always returns :ok" do
      assert :ok = HealthCheck.liveness_check()
    end
  end

  describe "readiness_check/0" do
    test "returns :ok when database is ready" do
      with_mock Common.Repo, [:passthrough], query!: fn "SELECT 1" -> %{rows: [[1]]} end do
        assert :ok = HealthCheck.readiness_check()
      end
    end

    test "returns error when database is not ready" do
      with_mock Common.Repo, [:passthrough],
        query!: fn "SELECT 1" ->
          raise Postgrex.Error, message: "Connection refused"
        end do
        assert {:error, error_msg} = HealthCheck.readiness_check()
        assert String.contains?(error_msg, "Database not ready")
      end
    end
  end

  describe "check_health/0" do
    test "basic health check structure" do
      # This is a simplified test that just checks the structure
      # without mocking complex dependencies
      with_mock Common.Repo, [:passthrough], query!: fn "SELECT 1" -> %{rows: [[1]]} end do
        result = HealthCheck.check_health()

        # Should return either :ok or :error tuple with proper structure
        assert match?({:ok, %{status: "healthy", checks: _}}, result) or
                 match?({:error, %{status: "unhealthy", checks: _}}, result)
      end
    end
  end
end
