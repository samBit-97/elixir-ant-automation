defmodule Common.Api.ApiContext do
  defstruct [
    :api_request,
    :headers,
    :url,
    :expected_transit_day
  ]
end
