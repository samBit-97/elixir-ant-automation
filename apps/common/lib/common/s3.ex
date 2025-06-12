defmodule Common.S3 do
  @moduledoc """
  Generic Wrapper around S3

  Usage:
    bucket = Common.S3.bucket()
  """

  @behaviour Common.S3.S3Behaviour

  @spec bucket() :: String.t()
  def bucket do
    Application.fetch_env!(:common, __MODULE__)[:s3_bucket]
  end

  @spec list_keys(String.t(), keyword()) :: Enumerable.t()
  def list_keys(bucket, opts \\ []) do
    ExAws.S3.list_objects_v2(bucket, opts)
    |> ExAws.stream!()
    |> Stream.map(& &1.key)
  end
end
