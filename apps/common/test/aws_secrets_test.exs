defmodule Common.AwsSecretsTest do
  use ExUnit.Case, async: true
  import Mox
  import Mock

  alias Common.AwsSecrets

  setup :verify_on_exit!

  setup do
    # Mock ExAws for testing
    Application.put_env(:ex_aws, :access_key_id, "test_key")
    Application.put_env(:ex_aws, :secret_access_key, "test_secret")
    Application.put_env(:ex_aws, :region, "us-east-1")
    :ok
  end

  describe "get_rds_credentials/1" do
    test "returns credentials for valid secret" do
      secret_json = Jason.encode!(%{"username" => "test_user", "password" => "test_pass"})

      with_mock ExAws, [:passthrough],
        request: fn _ ->
          {:ok, %{"SecretString" => secret_json}}
        end do
        assert {:ok, %{username: "test_user", password: "test_pass"}} =
                 AwsSecrets.get_rds_credentials("test/secret")
      end
    end

    test "returns error for invalid secret format" do
      with_mock ExAws, [:passthrough],
        request: fn _ ->
          {:ok, %{"SecretString" => "invalid json"}}
        end do
        assert {:error, "Unable to fetch RDS credentials"} =
                 AwsSecrets.get_rds_credentials("test/secret")
      end
    end

    test "returns error for AWS service failure" do
      with_mock ExAws, [:passthrough],
        request: fn _ ->
          {:error, {:http_error, 500, "Internal Server Error"}}
        end do
        assert {:error, "Unable to fetch RDS credentials"} =
                 AwsSecrets.get_rds_credentials("test/secret")
      end
    end

    test "returns error for missing username in secret" do
      secret_json = Jason.encode!(%{"password" => "test_pass"})

      with_mock ExAws, [:passthrough],
        request: fn _ ->
          {:ok, %{"SecretString" => secret_json}}
        end do
        assert {:error, "Unable to fetch RDS credentials"} =
                 AwsSecrets.get_rds_credentials("test/secret")
      end
    end

    test "returns error for missing password in secret" do
      secret_json = Jason.encode!(%{"username" => "test_user"})

      with_mock ExAws, [:passthrough],
        request: fn _ ->
          {:ok, %{"SecretString" => secret_json}}
        end do
        assert {:error, "Unable to fetch RDS credentials"} =
                 AwsSecrets.get_rds_credentials("test/secret")
      end
    end

    test "returns error for invalid secret ID" do
      assert {:error, "Invalid secret ID format"} =
               AwsSecrets.get_rds_credentials("")

      assert {:error, "Invalid secret ID format"} =
               AwsSecrets.get_rds_credentials(nil)

      assert {:error, "Invalid secret ID format"} =
               AwsSecrets.get_rds_credentials(123)
    end

    test "returns error for secret ID too long" do
      long_secret_id = String.duplicate("a", 513)

      assert {:error, "Invalid secret ID format"} =
               AwsSecrets.get_rds_credentials(long_secret_id)
    end
  end
end

