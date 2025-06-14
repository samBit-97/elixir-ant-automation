defmodule Etl.SamplerTest do
  alias EtlPipeline.Etl.Sampler
  alias Common.Model
  use ExUnit.Case, async: true

  test "sample/1 atmost k random samples per transit day" do
    models =
      Enum.flat_map(1..3, fn day ->
        Enum.map(1..10, fn i ->
          %Model{
            origin: "A#{i}",
            destination: "B#{i}",
            expected_transit_day: day,
            shipper: "shipper#{i}"
          }
        end)
      end)

    result =
      models
      |> Flow.from_enumerable()
      |> Sampler.sample(10)
      |> Enum.to_list()

    # IO.inspect(result)
    grouped = Enum.group_by(result, & &1.expected_transit_day)

    assert Enum.all?(grouped, fn {_day, item} -> length(item) <= 10 end)
    assert length(result) <= 30
  end
end
