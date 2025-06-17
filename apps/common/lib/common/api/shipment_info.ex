defmodule Common.Api.ShipmentInfo do
  @derive Jason.Encoder
  defstruct [:consignee_info, :international, :hold_at_address, :shipment_type]
end
