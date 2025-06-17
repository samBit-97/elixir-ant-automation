defmodule Common.Api.PrintingInfo do
  @derive Jason.Encoder
  defstruct [
    :resolution,
    :printer_name,
    :printer_ip
  ]
end
