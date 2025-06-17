defmodule Common.Api.ReturnAddress do
  @derive Jason.Encoder
  defstruct [
    :address1,
    :city,
    :country_code,
    :postal_code,
    :state_province
  ]
end
