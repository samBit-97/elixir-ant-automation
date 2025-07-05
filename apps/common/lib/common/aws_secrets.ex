defmodule Common.AwsSecrets do
  @moduledoc """
  Documentation for `Common.AwsSecrets`.

  Get credentials for RDS from AWS SecretsManager
  """
  @spec get_rds_credentials(String.t()) :: {:ok, map} | {:error, String.t()}
  def get_rds_credentials(secret_id \\ "prod/rds/credentials") do
    if is_valid_secret_id?(secret_id) do
      case fetch_secret(secret_id) do
        {:ok, %{"username" => username, "password" => password}} when is_binary(username) and is_binary(password) ->
          {:ok, %{username: username, password: password}}
        {:ok, _incomplete_secret} ->
          {:error, "Unable to fetch RDS credentials"}
        {:error, _reason} ->
          {:error, "Unable to fetch RDS credentials"}
      end
    else
      {:error, "Invalid secret ID format"}
    end
  end

  defp fetch_secret(secret_id) do
    secret_id
    |> ExAws.SecretsManager.get_secret_value()
    |> ExAws.request()
    |> case do
      {:ok, %{"SecretString" => secret_string}} ->
        case Jason.decode(secret_string) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, _} -> {:error, "Invalid secret format"}
        end
      {:error, _} -> {:error, "Failed to retrieve secret"}
    end
  end

  defp is_valid_secret_id?(secret_id) when is_binary(secret_id) do
    String.length(secret_id) > 0 and String.length(secret_id) <= 512
  end
  defp is_valid_secret_id?(_), do: false
end
