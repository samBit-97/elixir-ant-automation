defmodule Common.HttpoisonClient do
  @behaviour Common.HttpClient

  @impl true
  def post(url, body, headers, opts) do
    HTTPoison.post(url, body, headers, opts)
  end
end
