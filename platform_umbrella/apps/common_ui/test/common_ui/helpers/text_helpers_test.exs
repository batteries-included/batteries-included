defmodule CommonUI.TextHelpersTest do
  use ExUnit.Case

  import CommonUI.TextHelpers

  describe "obfuscate/1" do
    test "should obfuscate a value with default options" do
      assert obfuscate("abcdefghijklmnop") == "abcd********mnop"
    end

    test "should limit obfuscation characters with a really long string" do
      assert obfuscate("abcdefghijklmmmmmmmmmmmmmmmmmmmmmmnopqrstuvwxyz") == "abcd******************************wxyz"
    end

    test "should obfuscate a value with custom options" do
      assert obfuscate("abcdefghijklmnop", keep: 2, char: "#", char_limit: 2) == "ab##op"
    end

    test "should return original string if it's not long enough" do
      assert obfuscate("abc") == "abc"
    end
  end
end
