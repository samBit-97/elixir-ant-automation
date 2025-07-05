defmodule EtlPipeline.HealthCheck do
  @moduledoc """
  Health check module for monitoring application status.
  """

  alias Common.Repo
  alias Common.S3

  @doc """
  Performs a comprehensive health check of the application.
  Returns {:ok, status} or {:error, reason}
  """
  def check_health do
    checks = [
      {"database", &check_database/0},
      {"s3", &check_s3/0},
      {"configuration", &check_configuration/0},
      {"oban", &check_oban/0}
    ]

    results = Enum.map(checks, fn {name, check_fn} ->
      case check_fn.() do
        :ok -> {name, :ok}
        {:error, reason} -> {name, {:error, reason}}
      end
    end)

    failed_checks = Enum.filter(results, fn {_, status} -> 
      match?({:error, _}, status) 
    end)

    case failed_checks do
      [] -> {:ok, %{status: "healthy", checks: Map.new(results)}}
      _ -> {:error, %{status: "unhealthy", checks: Map.new(results)}}
    end
  end

  @doc """
  Quick liveness check - returns :ok if the application is running
  """
  def liveness_check do
    :ok
  end

  @doc """
  Readiness check - returns :ok if the application is ready to serve traffic
  """
  def readiness_check do
    case check_database() do
      :ok -> :ok
      {:error, reason} -> {:error, "Database not ready: #{reason}"}
    end
  end

  defp check_database do
    try do
      Repo.query!("SELECT 1")
      :ok
    rescue
      e -> {:error, "Database connection failed: #{Exception.message(e)}"}
    end
  end

  defp check_s3 do
    try do
      s3_module = Application.get_env(:common, :s3, S3)
      bucket = Application.get_env(:common, :s3_bucket, "tnt-automation")
      
      case s3_module.list_objects(bucket, prefix: "health-check") do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, "S3 access failed: #{inspect(reason)}"}
      end
    rescue
      e -> {:error, "S3 health check failed: #{Exception.message(e)}"}
    end
  end

  defp check_configuration do
    required_configs = [
      {:etl_pipeline, :api_url},
      {:etl_pipeline, :whm_client_id},
      {:etl_pipeline, :auth_token},
      {:common, :s3_bucket}
    ]

    missing_configs = 
      required_configs
      |> Enum.filter(fn {app, key} -> 
        Application.get_env(app, key) |> is_nil()
      end)

    case missing_configs do
      [] -> :ok
      missing -> 
        missing_list = Enum.map(missing, fn {app, key} -> "#{app}.#{key}" end)
        {:error, "Missing configurations: #{Enum.join(missing_list, ", ")}"}
    end
  end

  defp check_oban do
    try do
      case Oban.check_queue(EtlPipeline.Oban, queue: :etl_files) do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, "Oban queue check failed: #{inspect(reason)}"}
      end
    rescue
      e -> {:error, "Oban health check failed: #{Exception.message(e)}"}
    end
  end
end