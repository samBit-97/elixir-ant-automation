defmodule EtlPipeline.Etl.FileStreamer do
  require Logger
  alias Common.{Util, RowInfo, Model, S3}

  def stream_s3_bucket(s3_key) do
    bucket = S3.bucket()

    Logger.info("📂 [FileStreamer] Streaming S3 file: #{bucket}/#{s3_key}")

    ExAws.S3.get_object(bucket, s3_key)
    |> ExAws.stream!()
    |> Flow.from_enumerable()
    |> Flow.flat_map(&split_lines/1)
    |> Flow.map(&parse_line(&1, s3_key))
  end

  defp split_lines(chunk) do
    chunk
    |> to_string()
    |> String.split(["\n", "\r\n"], trim: true)
  end

  defp parse_line(line, shipper) do
    columns = String.split(line, "|")

    %Model{
      origin: columns |> Enum.at(0, "") |> String.trim(),
      destination: columns |> Enum.at(1, "") |> String.trim(),
      expected_transit_day: columns |> Enum.at(3, "") |> String.trim(),
      shipper: shipper
    }
  end

  def stream_file(file_path, origin) do
    File.stream!(file_path)
    |> CSV.decode!(headers: true)
    |> Flow.from_enumerable()
    |> Flow.map(&map_to_row(&1, origin))
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
