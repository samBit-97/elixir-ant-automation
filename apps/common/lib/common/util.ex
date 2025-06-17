defmodule Common.Util do
  def parse_float(nil), do: nil
  def parse_float(""), do: nil

  def parse_float(val) do
    case Float.parse(val) do
      {float, _} -> float
      :error -> nil
    end
  end

  def parse_bool("true"), do: true
  def parse_bool("false"), do: false
  def parse_bool(_), do: nil
end
