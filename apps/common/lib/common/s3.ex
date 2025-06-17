defmodule Common.S3 do
  @moduledoc """
  Generic Wrapper around S3

  Usage:
    bucket = Common.S3.bucket()
  """

  @behaviour Common.S3.S3Behaviour

  @spec list_keys(String.t(), keyword()) :: Enumerable.t()
  @impl true
  def list_keys(bucket, opts \\ []) do
    ExAws.S3.list_objects_v2(bucket, opts)
    |> ExAws.stream!()
    |> Stream.map(& &1.key)
  end

  @spec get_object(String.t(), String.t()) :: Enumerable.t()
  @impl true
  def get_object(bucket, key) do
    ExAws.S3.download_file(bucket, key, :memory)
    |> ExAws.stream!()
  end
end
