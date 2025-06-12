defmodule EtlPipeline.Etl.Validator do
  require Logger
  alias Common.Api.{ApiContext, ApiRequest, ShipmentInfo, ConsigneeInfo, PackageInfo}

  def validate(%ApiContext{
        api_request:
          %ApiRequest{
            package_info: %PackageInfo{
              shipper_id: shipper_id,
              loc: origin
            },
            shipment_info: %ShipmentInfo{
              consignee_info: %ConsigneeInfo{
                postal_code: destination
              }
            }
          } = request,
        headers: headers,
        url: url,
        expected_transit_day: expected_transit_day
      }) do
    {:ok, json_body} = Jason.encode(request)

    Logger.info("🚀 [Validator] Posting to URL: #{url}")

    {time_taken_us, response} =
      :timer.tc(fn ->
        HTTPoison.post(
          url,
          json_body,
          headers,
          recv_timeout: 15_000
        )
      end)

    time_taken_ms = div(time_taken_us, 1000)

    actual_trasit_days = parse_transit_days(response)

    if actual_trasit_days do
      success = actual_trasit_days == expected_transit_day

      %EtlPipeline.TestCaseResult{
        shipper_id: shipper_id,
        origin: origin,
        destination: destination,
        expected_transit_days: expected_transit_day,
        actual_transit_days: actual_trasit_days,
        success: success,
        request_payload: request,
        response_payload: parse_response_payload(response),
        time_taken_ms: time_taken_ms
      }
    else
      Logger.warning("Skipping test case")
      nil
    end
  end

  defp parse_transit_days(%HTTPoison.Response{body: body}) do
    case Jason.decode(body) do
      {:ok, %{"ratesMap" => rates_map}} when is_list(rates_map) ->
        rates_map
        |> Enum.flat_map(fn %{"value" => rates} -> rates end)
        |> Enum.find_value(fn %{
                                "serviceName" => service_name,
                                "transitDays" => transit_days,
                                "serviceSymbol" => service_symbol
                              } ->
          if String.downcase(service_name) == "ups ground" or
               String.ends_with?(service_symbol, ".GND") do
            transit_days
          else
            nil
          end
        end)

      _ ->
        Logger.warning("Could not parse transit days from response")
        nil
    end
  end

  defp parse_response_payload(%HTTPoison.Response{body: body}) do
    case Jason.decode(body) do
      {:ok, parsed} ->
        parsed

      _ ->
        %{}
    end
  end
end
