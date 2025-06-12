defmodule Common.S3.S3Behaviour do
  @callback list_keys(String.t(), keyword()) :: Enumerable.t()
end
