defmodule EtlPipeline.Workers.EtlFileJobTest do
  use ExUnit.Case, async: true
  import Mock

  alias EtlPipeline.Workers.EtlFileJob
  alias Oban.Job
  alias EtlPipeline.Etl.{FileStreamer, Sampler, Enricher, Validator}
  alias Common.{Model, RowInfo}
  alias Common.Api.{ApiContext, ApiRequest, ShipmentInfo, ConsigneeInfo, PackageInfo}

  setup do
    # Set up required configuration for enricher
    Application.put_env(:etl_pipeline, :default_first_name, "Test")
    Application.put_env(:etl_pipeline, :default_last_name, "User")
    Application.put_env(:etl_pipeline, :default_contact, "Test Contact")
    Application.put_env(:etl_pipeline, :default_phone, "555-0123")
    Application.put_env(:etl_pipeline, :hold_at_address1, "123 Test St")
    Application.put_env(:etl_pipeline, :hold_at_city, "Test City")
    Application.put_env(:etl_pipeline, :hold_at_contact, "Test Contact")
    Application.put_env(:etl_pipeline, :hold_at_company, "Test Company")
    Application.put_env(:etl_pipeline, :hold_at_country, "USA")
    Application.put_env(:etl_pipeline, :hold_at_postal_code, "12345")
    Application.put_env(:etl_pipeline, :hold_at_state, "TX")
    Application.put_env(:etl_pipeline, :hold_at_email, "test@example.com")
    Application.put_env(:etl_pipeline, :hold_at_phone, "555-0123")
    Application.put_env(:etl_pipeline, :return_address1, "456 Return St")
    Application.put_env(:etl_pipeline, :return_city, "Return City")
    Application.put_env(:etl_pipeline, :return_country, "USA")
    Application.put_env(:etl_pipeline, :return_postal_code, "67890")
    Application.put_env(:etl_pipeline, :return_state, "CA")
    Application.put_env(:etl_pipeline, :printer_name, "test_printer")
    Application.put_env(:etl_pipeline, :printer_ip, "127.0.0.1")

    :ok
  end

  @sample_model %Model{
    shipper: "SHIP123",
    origin: "ORD",
    destination: "NYC",
    expected_transit_day: 3
  }

  @row_info %RowInfo{
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

  @test_case_result %{
    shipper_id: "SHIP123",
    origin: "ORD",
    destination: "NYC",
    expected_transit_days: 3,
    actual_transit_days: 3,
    success: true,
    request_payload: %{},
    response_payload: %{},
    time_taken_ms: 100
  }

  test "perform/1 successfully processes a file" do
    file_path = "test/file.csv"
    job = %Job{args: %{"file" => file_path}}

    # Mock the entire pipeline
    with_mock FileStreamer, [:passthrough],
      stream_s3_bucket: fn ^file_path -> [@sample_model] end,
      stream_file: fn _, "ORD" -> [@row_info] end do
      with_mock Sampler, [:passthrough], sample: fn [@sample_model], 10 -> [@sample_model] end do
        with_mock Enricher, [:passthrough],
          enrich: fn @sample_model, _ ->
            %ApiContext{
              api_request: %ApiRequest{
                package_info: %PackageInfo{shipper_id: "SHIP123", loc: "ORD"},
                shipment_info: %ShipmentInfo{
                  consignee_info: %ConsigneeInfo{postal_code: "NYC"}
                }
              },
              headers: [],
              url: "http://localhost:8083/ORD/rate/qualifiedcarriers",
              expected_transit_day: 3
            }
          end do
          with_mock Validator, [:passthrough],
            validate: fn %ApiContext{} -> @test_case_result end do
            result = EtlFileJob.perform(job)
            assert result == :ok
          end
        end
      end
    end
  end

  test "perform/1 handles empty file" do
    file_path = "test/empty_file.csv"
    job = %Job{args: %{"file" => file_path}}

    with_mock FileStreamer, [:passthrough], stream_s3_bucket: fn ^file_path -> [] end do
      with_mock Sampler, [:passthrough], sample: fn [], 10 -> [] end do
        result = EtlFileJob.perform(job)
        assert result == :ok
      end
    end
  end

  test "perform/1 filters out invalid samples" do
    file_path = "test/file.csv"
    job = %Job{args: %{"file" => file_path}}

    invalid_sample = %Model{
      # Invalid shipper
      shipper: nil,
      origin: "ORD",
      destination: "NYC",
      expected_transit_day: 3
    }

    with_mock FileStreamer, [:passthrough],
      stream_s3_bucket: fn ^file_path -> [invalid_sample] end do
      with_mock Sampler, [:passthrough],
        sample: fn [invalid_sample], 10 -> [invalid_sample] end do
        with_mock Enricher, [:passthrough], enrich: fn ^invalid_sample, _ -> nil end do
          with_mock Validator, [:passthrough], validate: fn nil -> nil end do
            result = EtlFileJob.perform(job)
            assert result == :ok
          end
        end
      end
    end
  end

  test "perform/1 processes multiple samples" do
    file_path = "test/multi_file.csv"
    job = %Job{args: %{"file" => file_path}}

    sample1 = %Model{
      shipper: "SHIP123",
      origin: "ORD",
      destination: "NYC",
      expected_transit_day: 3
    }

    sample2 = %Model{
      shipper: "SHIP456",
      origin: "LAX",
      destination: "SFO",
      expected_transit_day: 2
    }

    with_mock FileStreamer, [:passthrough],
      stream_s3_bucket: fn ^file_path -> [sample1, sample2] end,
      stream_file: fn _, origin ->
        case origin do
          "ORD" -> [@row_info]
          "LAX" -> [%RowInfo{@row_info | origin: "LAX"}]
        end
      end do
      with_mock Sampler, [:passthrough],
        sample: fn [sample1, sample2], 10 -> [sample1, sample2] end do
        with_mock Enricher, [:passthrough],
          enrich: fn sample, _ ->
            %ApiContext{
              api_request: %ApiRequest{
                package_info: %PackageInfo{shipper_id: sample.shipper, loc: sample.origin},
                shipment_info: %ShipmentInfo{
                  consignee_info: %ConsigneeInfo{postal_code: sample.destination}
                }
              },
              headers: [],
              url: "http://localhost:8083/#{sample.origin}/rate/qualifiedcarriers",
              expected_transit_day: sample.expected_transit_day
            }
          end do
          with_mock Validator, [:passthrough],
            validate: fn %ApiContext{} -> @test_case_result end do
            result = EtlFileJob.perform(job)
            assert result == :ok
          end
        end
      end
    end
  end
end
