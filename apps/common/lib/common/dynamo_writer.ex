defmodule Common.DynamoWriter do
  @moduledoc """
  Module for writing test case results to DynamoDB.

  This replaces the PostgreSQL TestCaseResult schema for better scalability
  and real-time dashboard integration.
  """

  @behaviour Common.DynamoWriter.Behaviour
  require Logger

  @doc """
  Write a test case result to DynamoDB.

  ## Parameters
  - `result` - Map containing test case result data

  ## Expected fields:
  - shipper_id: String identifier for the shipper
  - origin: String origin location
  - destination: String destination location
  - expected_transit_days: Integer expected transit time
  - actual_transit_days: Integer actual transit time
  - success: Boolean indicating if test passed
  - request_payload: Map containing the API request
  - response_payload: Map containing the API response
  - time_taken_ms: Integer time taken for the request
  """
  def write_test_result(result) do
    table_name = get_table_name()
    Logger.info("📝 [DynamoWriter] Using table: #{table_name}")

    item = %{
      "test_id" => generate_test_id(result),
      "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "file_key" => Map.get(result, :file_key, "unknown"),
      "shipper_id" => result.shipper_id,
      "origin" => result.origin,
      "destination" => result.destination,
      "expected_transit_days" => result.expected_transit_days,
      "actual_transit_days" => result.actual_transit_days,
      "success" => result.success,
      "request_payload" => convert_to_map(result.request_payload),
      "response_payload" => convert_to_map(result.response_payload),
      "time_taken_ms" => result.time_taken_ms,
      "ttl" => calculate_ttl()
    }

    Logger.info("📝 [DynamoWriter] Writing test result to #{table_name}")

    case ExAws.Dynamo.put_item(table_name, item) |> ExAws.request() do
      {:ok, _response} ->
        Logger.info("✅ [DynamoWriter] Successfully wrote test result")
        :ok

      {:error, reason} ->
        Logger.error("❌ [DynamoWriter] Failed to write test result: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Batch write multiple test results to DynamoDB for better performance.
  """
  def batch_write_test_results(results) when is_list(results) do
    table_name = get_table_name()
    Logger.info("📝 [DynamoWriter] Using table: #{table_name}")
    Logger.info("Results: #{inspect(results)}")

    # DynamoDB batch_write_item has a limit of 25 items
    results
    |> Enum.chunk_every(25)
    |> Enum.map(&write_batch(&1, table_name))
    |> Enum.all?(&(&1 == :ok))
    |> case do
      true -> :ok
      false -> {:error, :batch_write_failed}
    end
  end

  defp write_batch(batch, table_name) do
    items =
      Enum.map(batch, fn result ->
        %{
          "test_id" => generate_test_id(result),
          "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "file_key" => Map.get(result, "file_key", "unknown"),
          "shipper_id" => result["shipper_id"],
          "origin" => result["origin"],
          "destination" => result["destination"],
          "expected_transit_days" => result["expected_transit_days"],
          "actual_transit_days" => result["actual_transit_days"],
          "success" => result["success"],
          "request_payload" => clean_nested_map(result["request_payload"]),
          "response_payload" => clean_nested_map(result["response_payload"]),
          "time_taken_ms" => result["time_taken_ms"],
          "ttl" => calculate_ttl()
        }
      end)

    batch_requests =
      items
      |> Enum.map(&[put_request: [item: &1]])

    request_items = %{table_name => batch_requests}
    Logger.info("📝 [DynamoWriter] Table name: #{inspect(table_name)}")

    case ExAws.Dynamo.batch_write_item(request_items) |> ExAws.request() do
      {:ok, _response} ->
        Logger.info("✅ [DynamoWriter] Successfully batch wrote #{length(items)} results")
        :ok

      {:error, reason} ->
        Logger.error("❌ [DynamoWriter] Failed to batch write results: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp get_table_name do
    Application.get_env(:common, :dynamodb_table) ||
      raise "DYNAMODB_TABLE environment variable must be set"
  end

  defp generate_test_id(result) do
    # Create a unique test ID based on content and timestamp
    # Handle both atom and string keys for compatibility
    shipper_id = result["shipper_id"] || result[:shipper_id] || "unknown"
    origin = result["origin"] || result[:origin] || "unknown"
    destination = result["destination"] || result[:destination] || "unknown"
    content = "#{shipper_id}-#{origin}-#{destination}"
    timestamp = System.system_time(:microsecond)

    :crypto.hash(:sha256, "#{content}-#{timestamp}")
    |> Base.encode16(case: :lower)
    |> String.slice(0, 16)
  end

  defp calculate_ttl do
    # Set TTL to 90 days from now (in seconds since epoch)
    DateTime.utc_now()
    |> DateTime.add(30, :minute)
    |> DateTime.to_unix()
  end

  defp convert_to_map(data) when is_struct(data) do
    data
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {to_string(k), convert_to_map(v)} end)
  end

  defp convert_to_map(data) when is_list(data) do
    Enum.map(data, &convert_to_map/1)
  end

  defp convert_to_map(data) when is_map(data) and not is_struct(data) do
    Enum.into(data, %{}, fn {k, v} -> {to_string(k), convert_to_map(v)} end)
  end

  defp convert_to_map(data), do: data

  # Recursively clean nil values from nested maps for DynamoDB
  defp clean_nested_map(nil), do: nil

  defp clean_nested_map(data) when is_map(data) do
    data
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Enum.into(%{}, fn {k, v} -> {k, clean_nested_map(v)} end)
  end

  defp clean_nested_map(data) when is_list(data) do
    data
    |> Enum.map(&clean_nested_map/1)
    |> Enum.reject(&is_nil/1)
  end

  defp clean_nested_map(data), do: data
end
