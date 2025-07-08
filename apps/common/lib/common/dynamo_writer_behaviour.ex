defmodule Common.DynamoWriter.Behaviour do
  @moduledoc """
  Behaviour for DynamoDB writer module to enable mocking in tests.
  """

  @callback write_test_result(map()) :: :ok | {:error, term()}
  @callback batch_write_test_results(list(map())) :: :ok | {:error, term()}
end