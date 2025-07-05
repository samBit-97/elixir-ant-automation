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

    # Create a temporary test file
    test_file = "/tmp/test_enricher.csv"
    File.write!(test_file, "test,content")

    FileStreamerMock
    |> expect(:stream_file, fn ^test_file, "ORD" -> Flow.from_enumerable([@row]) end)

    assert %ApiContext{} = ctx = Enricher.enrich(sample, test_file)
    assert ctx.expected_transit_day == 3
    assert ctx.url == "http://localhost:8083/ORD/rate/qualifiedcarriers"

    # Clean up
    File.rm(test_file)
  end

  test "enrich/2 returns nil for invalid input" do
    sample = %Model{
      # Invalid shipper
      shipper: nil,
      origin: "ORD",
      destination: "NYC",
      expected_transit_day: 3
    }

    test_file = "/tmp/test_enricher.csv"
    File.write!(test_file, "test,content")

    assert is_nil(Enricher.enrich(sample, test_file))

    # Clean up
    File.rm(test_file)
  end

  test "enrich/2 returns nil for non-existent file" do
    sample = %Model{
      shipper: "SHIP123",
      origin: "ORD",
      destination: "NYC",
      expected_transit_day: 3
    }

    assert is_nil(Enricher.enrich(sample, "non/existent/file.csv"))
  end

  test "enrich/2 returns nil for missing configuration" do
    sample = %Model{
      shipper: "SHIP123",
      origin: "ORD",
      destination: "NYC",
      expected_transit_day: 3
    }

    test_file = "/tmp/test_enricher.csv"
    File.write!(test_file, "test,content")

    # Remove required configuration
    Application.delete_env(:etl_pipeline, :api_url)

    assert is_nil(Enricher.enrich(sample, test_file))

    # Clean up
    File.rm(test_file)
  end
end
