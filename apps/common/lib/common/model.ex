defmodule Common.Model do
  @moduledoc """
  Documentation for `Common.Model`.

  Struct for sample
  """

  @enforce_keys [:origin, :destination, :expected_transit_day, :shipper]
  defstruct [:origin, :destination, :expected_transit_day, :shipper]
end
