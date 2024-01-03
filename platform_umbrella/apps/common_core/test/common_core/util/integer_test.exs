defmodule CommonCore.Util.IntegerTest do
  use ExUnit.Case

  import CommonCore.Util.Integer

  describe "to_integer/1" do
    test "will parse a string" do
      assert to_integer("1") == 1
      assert to_integer("-1") == -1
    end

    test "will pass through an integer" do
      assert to_integer(1) == 1
      assert to_integer(-1) == -1
    end

    test "will parse a float" do
      assert to_integer(1.0) == 1
      assert to_integer(-1.0) == -1
    end

    test "will zero out nil" do
      assert to_integer(nil) == 0
    end
  end
end
