defmodule TntPipelineTest do
  use ExUnit.Case
  doctest TntPipeline

  test "greets the world" do
    assert TntPipeline.hello() == :world
  end
end
