defmodule EtlPipeline.Etl.FileStreamer do
  require Logger
  alias Common.Model
  alias Common.S3

  def stream(s3_key) do
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
end
