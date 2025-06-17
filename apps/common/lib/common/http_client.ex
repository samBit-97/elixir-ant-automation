defmodule Common.HttpClient do
  @callback post(String.t(), any(), list(), keyword()) ::
              {:ok, HTTPoison.Response.t()} | {:error, any()}
end
