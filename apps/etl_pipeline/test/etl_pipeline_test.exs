defmodule EtlPipelineTest do
  use ExUnit.Case
  doctest EtlPipeline

  test "greets the world" do
    assert EtlPipeline.hello() == :world
  end
end
