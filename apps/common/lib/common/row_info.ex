defmodule Common.RowInfo do
  @moduledoc """
  Documentation for `Common.RowInfo`.

  Struct for enriching sample
  """

  defstruct [
    :origin,
    :locn_nbr,
    :shipper_id,
    :barcode,
    :weight,
    :hazmat,
    :length,
    :width,
    :height,
    :address1,
    :city,
    :country,
    :postal_code,
    :state_province,
    :delivery_method,
    :locn_type
  ]
end
