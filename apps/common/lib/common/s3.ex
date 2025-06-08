defmodule Common.S3 do
  @moduledoc """
  Generic Wrapper around S3

  Usage:
    bucket = Common.S3.bucket()
  """

  @spec bucket :: String.t()
  def bucket do
    Application.fetch_env!(:common, __MODULE__)[:s3_bucket]
  end
end
