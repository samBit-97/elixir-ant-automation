defmodule Common.Api.HoldAtAddress do
  @derive Jason.Encoder
  defstruct [
    :address1,
    :address2,
    :address3,
    :city,
    :contact,
    :company,
    :country_code,
    :postal_code,
    :state_province,
    :email,
    :phone
  ]
end
