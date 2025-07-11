defmodule Etl.Sampler do
  @moduledoc """
  Documentation for `Etl.Sampler`.

  Uniform random sampling of `k` elements from a stream
  """

  def sample(stream, k \\ 10) do
    {reservoir, _seen} =
      stream
      |> Enum.reduce({[], 0}, fn item, {reservoir, seen} ->
        if length(reservoir) < k do
          {[item | reservoir], seen + 1}
        else
          j = :rand.uniform(seen + 1)

          if j <= k do
            index = :rand.uniform(k) - 1
            reservoir = List.replace_at(reservoir, index, item)
            {reservoir, seen + 1}
          else
            {reservoir, seen + 1}
          end
        end
      end)

    reservoir
  end
end
