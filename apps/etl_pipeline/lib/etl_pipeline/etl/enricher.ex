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
  @api_url "http://localhost:8081"

  def enrich(sample, dest_file_path) do
    row = get_first_match_shipper(dest_file_path, sample.shipper, sample.origin)

    if row do
      Logger.debug("🚀 [Enricher] Found row for shipper_id=#{sample.shipper} → Enriching.")
      build_api_context(row, sample)
    else
      Logger.warning(
        "⚠️ [Enricher] No row found in #{dest_file_path} for shipper_id=#{sample.shipper_id}"
      )

      nil
    end
  end

  defp build_api_context(%RowInfo{} = row, %Model{} = sample) do
    %ApiContext{
      api_request: build_api_request(row),
      headers: [
        {"Content-Type", "application/json"},
        {"Accept", "application/json"},
        {"X-WHM-CLIENT", "1234"},
        {"auth-token", "add your auth token here"}
      ],
      url: "#{@api_url}/#{sample.origin}/rate/qualifiedcarriers",
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
        first_name: "Sam",
        last_name: "007",
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
          contact: "Gary Haas",
          ## TODO: From sample.destination get the actual address details for the destination
          country_code: row.country,
          postal_code: row.postal_code,
          state_province: row.state_province,
          phone_number: "0"
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
        hold_at_address: %HoldAtAddress{
          address1: "7701 BISCAYNE BLVD",
          city: "LOS ANGELES",
          contact: "SABRINA OLIVARES",
          company: "ADVANCE AUTO PARTS STORE 9359",
          country_code: "USA",
          postal_code: "90019-3827",
          state_province: "CA",
          email: "OES.MACYS1@GMAIL.COM",
          phone: "0345678910"
        },
        shipment_type: "A"
      },
      printing_info: %PrintingInfo{
        resolution: 203,
        printer_name: "0.0.0.0",
        printer_ip: "0.0.0.0"
      },
      return_address: %ReturnAddress{
        address1: "2100 PLEASANT HILL RD RM 21",
        city: "DULUTH",
        country_code: "USA",
        postal_code: "30096",
        state_province: "GA"
      }
    }
  end
end
