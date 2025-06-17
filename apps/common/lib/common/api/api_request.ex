defmodule Common.Api.ApiRequest do
  @derive Jason.Encoder
  defstruct [
    :package_info,
    :shipment_info,
    :printing_info,
    :return_address
  ]
end
