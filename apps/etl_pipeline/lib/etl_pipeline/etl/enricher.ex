defmodule EtlPipeline.Etl.Enricher do
  require Logger
  alias EtlPipeline.Etl.FileStreamer
  alias Common.Model

  alias Common.Api.{
    PackageInfo,
    ApiRequest,
    ShipmentInfo,
    ReturnAddress,
    PrintingInfo,
    HoldAtAddress,
    LineItem,
    International,
    ConsigneeInfo,
    ApiContext
  }

  alias Common.RowInfo

  @api_date_layout "%Y-%m-%d"

  def enrich(sample, dest_file_path) do
    with :ok <- validate_input(sample, dest_file_path),
         :ok <- validate_auth_config(),
         row when not is_nil(row) <-
           get_first_match_shipper(dest_file_path, sample.shipper, sample.origin) do
      Logger.debug("🚀 [Enricher] Found row for shipper_id=#{sample.shipper} → Enriching.")
      build_api_context(row, sample)
    else
      {:error, reason} ->
        Logger.error("❌ [Enricher] Validation failed: #{reason}")
        nil

      nil ->
        Logger.warning(
          "⚠️ [Enricher] No row found in #{dest_file_path} for shipper_id=#{sample.shipper_id}"
        )

        nil
    end
  end

  defp build_api_context(%RowInfo{} = row, %Model{} = sample) do
    %ApiContext{
      api_request: build_api_request(row),
      headers: build_headers(),
      url: "#{get_api_url()}/#{sample.origin}/rate/qualifiedcarriers",
      expected_transit_day: sample.expected_transit_day
    }
  end

  defp get_first_match_shipper(dest_file_path, shipper, origin) do
    file_streamer = Application.get_env(:etl_pipeline, :file_streamer, FileStreamer)

    dest_file_path
    |> file_streamer.stream_file(origin)
    |> Enum.find(fn row -> row.shipper_id == shipper end)
  end

  defp build_api_request(%RowInfo{} = row) do
    ship_date = Date.utc_today()
    expected_delivery_date = Date.add(ship_date, 7)

    %ApiRequest{
      package_info: %PackageInfo{
        first_name: get_config(:default_first_name, "Customer"),
        last_name: get_config(:default_last_name, "Name"),
        actual_weight: row.weight,
        estimated_weight: row.weight,
        length: row.length |> trunc(),
        width: row.width |> trunc(),
        height: row.height |> trunc(),
        insured: false,
        package_number: row.barcode,
        delivery_method: row.delivery_method,
        saturday_delivery: false,
        sunday_delivery: false,
        po_box: false,
        residential: true,
        hazmat: false,
        ship_date: Calendar.strftime(ship_date, @api_date_layout),
        shipper_id: row.shipper_id,
        loc_type: row.locn_type,
        time_zone: "EST",
        expected_delivery_date: Calendar.strftime(expected_delivery_date, @api_date_layout),
        packages_scanned: 1,
        total_packages: 1,
        division: "71",
        loc: row.origin,
        is_package_override: true,
        shipper_reference: "915557987",
        consignee_reference: "470413217-1",
        package_total_cost: 25.0,
        dimension_required: false,
        department: ["349"]
      },
      shipment_info: %ShipmentInfo{
        consignee_info: %ConsigneeInfo{
          address1: row.address1,
          city: row.city,
          contact: get_config(:default_contact, "Customer Service"),
          ## TODO: From sample.destination get the actual address details for the destination
          country_code: row.country,
          postal_code: row.postal_code,
          state_province: row.state_province,
          phone_number: get_config(:default_phone, "000-000-0000")
        },
        international: %International{
          international: false,
          line_item_list: [
            %LineItem{
              item_id: 1,
              country_of_origin: "US",
              description: "TEST",
              harmonized_code: 111_111,
              unit_value: 1.0,
              unit_weight: 0.1,
              quantity: 1,
              line_number: 1,
              product_code: "32677682593",
              country_of_manufacture: "US"
            }
          ]
        },
        hold_at_address: build_hold_at_address(),
        shipment_type: "A"
      },
      printing_info: %PrintingInfo{
        resolution: 203,
        printer_name: get_config(:printer_name, "default_printer"),
        printer_ip: get_config(:printer_ip, "127.0.0.1")
      },
      return_address: build_return_address()
    }
  end

  defp get_api_url do
    Application.get_env(:etl_pipeline, :api_url) ||
      raise "API_URL environment variable not set"
  end

  defp build_headers do
    [
      {"Content-Type", "application/json"},
      {"Accept", "application/json"},
      {"X-WHM-CLIENT", get_config(:whm_client_id)},
      {"auth-token", get_config(:auth_token)}
    ]
  end

  defp build_hold_at_address do
    %HoldAtAddress{
      address1: get_config(:hold_at_address1),
      city: get_config(:hold_at_city),
      contact: get_config(:hold_at_contact),
      company: get_config(:hold_at_company),
      country_code: get_config(:hold_at_country, "USA"),
      postal_code: get_config(:hold_at_postal_code),
      state_province: get_config(:hold_at_state),
      email: get_config(:hold_at_email),
      phone: get_config(:hold_at_phone)
    }
  end

  defp build_return_address do
    %ReturnAddress{
      address1: get_config(:return_address1),
      city: get_config(:return_city),
      country_code: get_config(:return_country, "USA"),
      postal_code: get_config(:return_postal_code),
      state_province: get_config(:return_state)
    }
  end

  defp get_config(key, default \\ nil) do
    case Application.get_env(:etl_pipeline, key) do
      nil when default != nil -> default
      nil -> raise "Required configuration #{key} not set"
      value -> value
    end
  end

  defp validate_input(sample, dest_file_path) do
    cond do
      is_nil(sample) ->
        {:error, "Sample cannot be nil"}

      is_nil(sample.shipper) ->
        {:error, "Sample shipper cannot be nil"}

      is_nil(sample.origin) ->
        {:error, "Sample origin cannot be nil"}

      not is_binary(dest_file_path) ->
        {:error, "Destination file path must be a string"}

      String.length(dest_file_path) == 0 ->
        {:error, "Destination file path cannot be empty"}

      not File.exists?(dest_file_path) ->
        {:error, "Destination file does not exist"}

      true ->
        :ok
    end
  end

  defp validate_auth_config do
    required_configs = [:api_url, :whm_client_id, :auth_token]

    missing_configs =
      required_configs
      |> Enum.filter(fn key ->
        Application.get_env(:etl_pipeline, key) |> is_nil()
      end)

    case missing_configs do
      [] -> :ok
      missing -> {:error, "Missing required configuration: #{Enum.join(missing, ", ")}"}
    end
  end
end
