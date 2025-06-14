defmodule Etl.EnricherTest do
  use ExUnit.Case, async: true
  import Mox

  alias EtlPipeline.Etl.Enricher
  alias Common.{Model, RowInfo}
  alias Common.Api.ApiContext

  defmock(FileStreamerMock, for: EtlPipeline.Etl.FileStreamerBehaviour)

  setup :verify_on_exit!

  setup do
    Application.put_env(:etl_pipeline, :file_streamer, FileStreamerMock)
    :ok
  end

  @row %RowInfo{
    shipper_id: "SHIP123",
    origin: "ORD",
    weight: 2.5,
    length: 10.0,
    width: 10.0,
    height: 10.0,
    delivery_method: "GND",
    barcode: "123456789",
    locn_type: "DC",
    address1: "1 Main St",
    city: "Chicago",
    country: "USA",
    postal_code: "60606",
    state_province: "IL"
  }

  test "enrich/2 returns enriched ApiContext" do
    sample = %Model{
      shipper: "SHIP123",
      origin: "ORD",
      destination: "NYC",
      expected_transit_day: 3
    }

    FileStreamerMock
    |> expect(:stream_file, fn "dummy/path.csv", "ORD" -> Flow.from_enumerable([@row]) end)

    assert %ApiContext{} = ctx = Enricher.enrich(sample, "dummy/path.csv")
    assert ctx.expected_transit_day == 3
    assert ctx.url == "http://localhost:8081/ORD/rate/qualifiedcarriers"
  end
end
