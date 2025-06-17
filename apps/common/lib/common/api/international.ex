defmodule Common.Api.International do
  @derive Jason.Encoder
  defstruct [
    :international,
    :line_item_list
  ]
end
