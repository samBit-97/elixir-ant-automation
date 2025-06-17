defmodule Common.Api.LineItem do
  @derive Jason.Encoder
  defstruct [
    :item_id,
    :country_of_origin,
    :description,
    :harmonized_code,
    :unit_value,
    :unit_weight,
    :quantity,
    :line_number,
    :product_code,
    :country_of_manufacture
  ]
end
