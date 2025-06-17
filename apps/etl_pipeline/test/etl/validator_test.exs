defmodule Etl.ValidatorTest do
  use ExUnit.Case, async: true

  import Mox

  alias EtlPipeline.Etl.Validator
  alias Common.Api.{ApiContext, ApiRequest, ShipmentInfo, ConsigneeInfo, PackageInfo}
  alias EtlPipeline.TestCaseResult

  defmock(Common.HttpClientMock, for: Common.HttpClient)

  setup :verify_on_exit!

  setup do
    Application.put_env(:etl_pipeline, :http_client, Common.HttpClientMock)
    :ok
  end

  test "validate/1 returns TestCaseResult on transitDay match" do
    request = %ApiRequest{
      package_info: %PackageInfo{shipper_id: "SHIP123", loc: "ORD"},
      shipment_info: %ShipmentInfo{
        consignee_info: %ConsigneeInfo{postal_code: "NYC"}
      }
    }

    body =
      Jason.encode!(%{
        "ratesMap" => [
          %{
            "value" => [
              %{
                "serviceName" => "UPS Ground",
                "transitDays" => 3,
                "serviceSymbol" => "UPS.GND"
              }
            ]
          }
        ]
      })

    Common.HttpClientMock
    |> expect(:post, fn _url, _body, _headers, _opts ->
      {:ok, %HTTPoison.Response{body: body}}
    end)

    ctx = %ApiContext{
      api_request: request,
      headers: [],
      url: "https://fake-url",
      expected_transit_day: 3
    }

    result = Validator.validate(ctx)

    assert %TestCaseResult{
             origin: "ORD",
             destination: "NYC",
             shipper_id: "SHIP123",
             expected_transit_days: 3,
             actual_transit_days: 3,
             success: true
           } = result
  end
end
