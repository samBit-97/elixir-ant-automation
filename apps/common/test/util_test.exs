defmodule Common.UtilTest do
  use ExUnit.Case, async: true

  alias Common.Util

  describe "parse_float/1" do
    test "returns nil for nil input" do
      assert Util.parse_float(nil) == nil
    end

    test "returns nil for empty string" do
      assert Util.parse_float("") == nil
    end

    test "parses valid float string" do
      assert Util.parse_float("3.14") == 3.14
    end

    test "parses valid integer string as float" do
      assert Util.parse_float("42") == 42.0
    end

    test "parses float with trailing characters" do
      assert Util.parse_float("3.14abc") == 3.14
    end

    test "returns nil for invalid float string" do
      assert Util.parse_float("abc") == nil
    end

    test "returns nil for non-numeric string" do
      assert Util.parse_float("not_a_number") == nil
    end
  end

  describe "parse_bool/1" do
    test "returns true for 'true' string" do
      assert Util.parse_bool("true") == true
    end

    test "returns false for 'false' string" do
      assert Util.parse_bool("false") == false
    end

    test "returns nil for other strings" do
      assert Util.parse_bool("maybe") == nil
      assert Util.parse_bool("yes") == nil
      assert Util.parse_bool("no") == nil
      assert Util.parse_bool("1") == nil
      assert Util.parse_bool("0") == nil
    end

    test "returns nil for nil input" do
      assert Util.parse_bool(nil) == nil
    end

    test "returns nil for empty string" do
      assert Util.parse_bool("") == nil
    end
  end
end

