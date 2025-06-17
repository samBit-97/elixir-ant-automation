defmodule Common.Api.ConsigneeInfo do
  @derive Jason.Encoder
  defstruct [
    :address1,
    :city,
    :contact,
    :country_code,
    :postal_code,
    :state_province,
    :phone_number,
    :company,
    :email
  ]
end
