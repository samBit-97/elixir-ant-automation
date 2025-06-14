defmodule EtlPipeline.Etl.FileStreamerBehaviour do
  @callback stream_file(String.t(), String.t()) :: Enumerable.t()
end
