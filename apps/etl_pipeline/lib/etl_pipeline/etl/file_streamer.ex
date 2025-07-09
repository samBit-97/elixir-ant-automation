defmodule EtlPipeline.Etl.FileStreamer do
  @behaviour EtlPipeline.Etl.FileStreamerBehaviour
  require Logger
  alias Common.{Util, RowInfo, Model}

  def stream_s3_bucket(s3_key) do
    bucket = Application.fetch_env!(:common, :s3_bucket)

    Logger.info("📂 [FileStreamer] Streaming S3 file: #{bucket}/#{s3_key}")

    s3 = Application.fetch_env!(:common, :s3)

    s3.get_object(bucket, s3_key)
    |> Stream.flat_map(&split_lines/1)
    |> Stream.map(&parse_line(&1, s3_key))
    |> Enum.to_list()
  end

  defp split_lines(chunk) do
    chunk
    |> to_string()
    |> String.split(["\n", "\r\n"], trim: true)
  end

  defp parse_line(line, s3_key) do
    shipper = String.replace(s3_key, ".txt", "")
    columns = String.split(line, "|")

    %Model{
      origin: columns |> Enum.at(0, "") |> String.trim(),
      destination: columns |> Enum.at(1, "") |> String.trim(),
      expected_transit_day: parse_integer_field(columns, 3),
      shipper: shipper
    }
  end

  defp parse_integer_field(columns, index) do
    columns
    |> Enum.at(index, "")
    |> String.trim()
    |> case do
      "" -> 0  # Default to 0 for empty values
      value -> 
        case Integer.parse(value) do
          {int, _} -> int
          :error -> 0  # Default to 0 for invalid values
        end
    end
  end

  def stream_s3_dest_file(s3_key, origin) do
    bucket = Application.fetch_env!(:common, :s3_bucket)
    s3 = Application.fetch_env!(:common, :s3)

    Logger.info("📂 [FileStreamer] Streaming dest CSV from S3: #{bucket}/#{s3_key}")

    s3.get_object(bucket, s3_key)
    |> Stream.map(&to_string/1)
    |> Stream.flat_map(&String.split(&1, ["\n", "\r\n"], trim: true))
    |> CSV.decode!(headers: true, validate_row_length: false)
    |> Stream.filter(&valid_row?/1)
    |> Stream.map(&map_to_row(&1, origin))
    |> Enum.to_list()
  end

  @impl true
  def stream_file(file_path, origin) do
    File.stream!(file_path)
    |> CSV.decode!(headers: true)
    |> Stream.map(&map_to_row(&1, origin))
    |> Enum.to_list()
  end

  defp valid_row?(row) do
    required_fields = [
      "locn_nbr", "shipper_id", "barcode", "weight", "hazmat", 
      "length", "width", "height", "address1", "city", 
      "country", "postal_code", "state_province", "delivery_method", "locnType"
    ]
    
    Enum.all?(required_fields, &Map.has_key?(row, &1))
  end

  defp map_to_row(row, origin) do
    %RowInfo{
      origin: origin,
      locn_nbr: row["locn_nbr"] |> String.trim(),
      shipper_id: row["shipper_id"] |> String.trim(),
      barcode: row["barcode"] |> String.trim(),
      weight: row["weight"] |> Util.parse_float(),
      hazmat: row["hazmat"] |> Util.parse_bool(),
      length: row["length"] |> Util.parse_float(),
      width: row["width"] |> Util.parse_float(),
      height: row["height"] |> Util.parse_float(),
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
