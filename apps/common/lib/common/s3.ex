defmodule Common.S3 do
  @moduledoc """
  Generic Wrapper around S3

  Usage:
    bucket = Common.S3.bucket()
  """

  require Logger
  @behaviour Common.S3.S3Behaviour

  @spec list_keys(String.t(), keyword()) :: Enumerable.t()
  @impl true
  def list_keys(bucket, opts \\ []) do
    Logger.info("Listing S3 objects", bucket: bucket, opts: opts)

    try do
      ExAws.S3.list_objects_v2(bucket, opts)
      |> ExAws.stream!()
      |> Stream.map(& &1.key)
    rescue
      e ->
        Logger.error("Failed to list S3 objects",
          bucket: bucket,
          error: Exception.message(e),
          opts: opts
        )

        reraise e, __STACKTRACE__
    end
  end

  @spec get_object(String.t(), String.t()) :: Enumerable.t()
  @impl true
  def get_object(bucket, key) do
    Logger.info("Downloading S3 object", bucket: bucket, key: key)

    try do
      ExAws.S3.download_file(bucket, key, :memory)
      |> ExAws.stream!()
    rescue
      e ->
        Logger.error("Failed to download S3 object",
          bucket: bucket,
          key: key,
          error: Exception.message(e)
        )

        reraise e, __STACKTRACE__
    end
  end

  @spec list_objects(String.t(), keyword()) :: {:ok, list()} | {:error, term()}
  @impl true
  def list_objects(bucket, opts \\ []) do
    Logger.info("Listing S3 objects with result", bucket: bucket, opts: opts)

    try do
      result =
        ExAws.S3.list_objects_v2(bucket, opts)
        |> ExAws.request()

      case result do
        {:ok, response} ->
          Logger.debug("Successfully listed S3 objects",
            bucket: bucket,
            count: length(response.contents)
          )

          {:ok, response.contents}

        {:error, reason} ->
          Logger.error("Failed to list S3 objects",
            bucket: bucket,
            error: inspect(reason)
          )

          {:error, reason}
      end
    rescue
      e ->
        Logger.error("Exception while listing S3 objects",
          bucket: bucket,
          error: Exception.message(e)
        )

        {:error, Exception.message(e)}
    end
  end
end
