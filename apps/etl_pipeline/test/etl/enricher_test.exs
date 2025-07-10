defmodule Etl.EnricherTest do
  use ExUnit.Case, async: true
  import Mox

  alias EtlPipeline.Etl.Enricher
  alias Common.{Model, RowInfo}
  alias Common.Api.ApiContext

  setup :verify_on_exit!

  setup do
    # Set up the cache with test data
    setup_cache_with_test_data()
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

  test "enrich/1 returns enriched ApiContext" do
    sample = %Model{
      shipper: "SHIP123",
      origin: "ORD",
      destination: "NYC",
      expected_transit_day: 3
    }

    assert %ApiContext{} = ctx = Enricher.enrich(sample)
    assert ctx.expected_transit_day == 3
    assert ctx.url == "http://localhost:8083/ORD/rate/qualifiedcarriers"
  end

  test "enrich/1 returns nil for invalid input" do
    sample = %Model{
      # Invalid shipper
      shipper: nil,
      origin: "ORD",
      destination: "NYC",
      expected_transit_day: 3
    }

    assert is_nil(Enricher.enrich(sample))
  end

  test "enrich/1 returns nil for non-existent shipper" do
    sample = %Model{
      shipper: "NONEXISTENT",
      origin: "ORD",
      destination: "NYC",
      expected_transit_day: 3
    }

    assert is_nil(Enricher.enrich(sample))
  end

  test "enrich/1 returns nil for missing configuration" do
    sample = %Model{
      shipper: "SHIP123",
      origin: "ORD",
      destination: "NYC",
      expected_transit_day: 3
    }

    # Clear required config
    original_url = Application.get_env(:etl_pipeline, :api_url)
    Application.delete_env(:etl_pipeline, :api_url)

    assert is_nil(Enricher.enrich(sample))

    # Restore config
    Application.put_env(:etl_pipeline, :api_url, original_url)
  end

  # Helper function to set up cache with test data
  defp setup_cache_with_test_data do
    # Insert test data directly into cache ETS table
    cache_name = EtlPipeline.Etl.DestinationCache
    
    # Ensure the cache process is started and loaded
    Process.sleep(100)  # Give the cache time to initialize
    
    # Insert test data directly into ETS table
    :ets.insert(cache_name, {{"SHIP123"}, @row})
  end
end
