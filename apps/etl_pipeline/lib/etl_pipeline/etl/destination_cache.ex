defmodule EtlPipeline.Etl.DestinationCache do
  @moduledoc """
  In-memory cache for destination CSV data to avoid repeated S3 downloads.

  Loads dest.csv once and provides fast lookups by shipper_id and origin.
  """

  use GenServer
  require Logger
  alias Common.RowInfo

  @cache_name __MODULE__

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: @cache_name)
  end

  @spec get_row(String.t()) :: RowInfo.t() | nil
  def get_row(shipper_id) do
    case :ets.lookup(@cache_name, {shipper_id}) do
      [{_key, row}] -> row
      [] -> nil
    end
  end

  @spec reload() :: :ok
  def reload do
    GenServer.call(@cache_name, :reload)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Create ETS table for fast lookups
    :ets.new(@cache_name, [:named_table, :set, :public, read_concurrency: true])

    # Load data immediately
    send(self(), :load_data)

    {:ok, %{}}
  end

  @impl true
  def handle_call(:reload, _from, state) do
    send(self(), :load_data)
    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:load_data, state) do
    load_destination_data()
    {:noreply, state}
  end

  # Private functions

  defp load_destination_data do
    Logger.info("🏗️ [DestinationCache] Loading destination data from S3...")

    dest_s3_key = Application.get_env(:etl_pipeline, :dest_s3_key, "config/dest.csv")

    try do
      # Clear existing data
      :ets.delete_all_objects(@cache_name)

      # Load all destination data and index by {shipper_id, origin}
      dest_s3_key
      |> load_dest_csv_from_s3()
      |> Enum.each(fn row ->
        key = {row.shipper_id}
        :ets.insert(@cache_name, {key, row})
      end)

      count = :ets.info(@cache_name, :size)
      Logger.info("✅ [DestinationCache] Loaded #{count} destination records")
    rescue
      error ->
        Logger.error("❌ [DestinationCache] Failed to load destination data: #{inspect(error)}")
    end
  end

  defp load_dest_csv_from_s3(s3_key) do
    bucket = Application.fetch_env!(:common, :s3_bucket)
    s3 = Application.fetch_env!(:common, :s3)

    Logger.info("📂 [DestinationCache] Loading CSV from S3: #{bucket}/#{s3_key}")

    s3.get_object(bucket, s3_key)
    |> Stream.map(&to_string/1)
    |> Stream.flat_map(&String.split(&1, ["\n", "\r\n"], trim: true))
    |> CSV.decode!(headers: true, validate_row_length: false)
    |> Stream.filter(&valid_row?/1)
    |> Enum.map(&map_to_row_info/1)
  end

  defp valid_row?(row) do
    required_fields = [
      "locn_nbr",
      "shipper_id",
      "barcode",
      "weight",
      "hazmat",
      "length",
      "width",
      "height",
      "address1",
      "city",
      "country",
      "postal_code",
      "state_province",
      "delivery_method",
      "locnType"
    ]

    Enum.all?(required_fields, &Map.has_key?(row, &1))
  end

  defp map_to_row_info(row) do
    # Extract origin from locn_nbr (first part before any delimiter if needed)
    origin = row["locn_nbr"] |> String.trim()

    %RowInfo{
      origin: origin,
      locn_nbr: row["locn_nbr"] |> String.trim(),
      shipper_id: row["shipper_id"] |> String.trim(),
      barcode: row["barcode"] |> String.trim(),
      weight: row["weight"] |> Common.Util.parse_float(),
      hazmat: row["hazmat"] |> Common.Util.parse_bool(),
      length: row["length"] |> Common.Util.parse_float(),
      width: row["width"] |> Common.Util.parse_float(),
      height: row["height"] |> Common.Util.parse_float(),
      address1: row["address1"] |> String.trim(),
      city: row["city"] |> String.trim(),
      country: row["country"] |> String.trim(),
      postal_code: row["postal_code"] |> String.trim(),
      state_province: row["state_province"] |> String.trim(),
      delivery_method: row["delivery_method"] |> String.trim(),
      locn_type: row["locnType"] |> String.trim()
    }
  end
end
