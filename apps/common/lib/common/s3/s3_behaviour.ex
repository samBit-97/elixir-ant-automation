defmodule Common.S3.S3Behaviour do
  @callback list_keys(String.t(), keyword()) :: Enumerable.t()
  @callback get_object(String.t(), String.t()) :: Enumerable.t()
  @callback list_objects(String.t(), keyword()) :: {:ok, list()} | {:error, term()}
end
