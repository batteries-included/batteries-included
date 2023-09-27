defmodule CommonCore.Util.MemoryTest do
  use ExUnit.Case

  alias CommonCore.Util.Memory

  describe "format_bytes/2" do
    test "handles nil input" do
      assert Memory.format_bytes(nil) == nil
    end

    test "handles binary input" do
      assert Memory.format_bytes("1024") == "1KB"
    end

    test "formats to bytes" do
      assert Memory.format_bytes(999) == "999 bytes"
    end

    test "formats to KB" do
      assert Memory.format_bytes(1024) == "1KB"
      assert Memory.format_bytes(2048, true) == "2KB"
    end

    test "formats to MB" do
      assert Memory.format_bytes(1_048_576) == "1MB"
      assert Memory.format_bytes(1_572_864, true) == "2MB"
    end

    test "formats to GB" do
      assert Memory.format_bytes(1_073_741_824) == "1GB"
      assert Memory.format_bytes(137_438_953_472, true) == "128GB"
    end

    test "formats to TB" do
      assert Memory.format_bytes(1_099_511_627_776) == "1TB"
      assert Memory.format_bytes(3_839_143_349_769, true) == "3.5TB"
    end
  end

  describe "bytes_as_select_options/1" do
    test "generates select options" do
      options = [1024, 1_048_576]
      assert Memory.bytes_as_select_options(options) == [{"1KB", 1024}, {"1MB", 1_048_576}]
    end
  end

  describe "gb_to_bytes/2" do
    test "converts GB to bytes as integer" do
      assert Memory.gb_to_bytes(1) == 1_073_741_824
    end
  end

  describe "mb_to_bytes/2" do
    test "converts MB to bytes as integer" do
      assert Memory.mb_to_bytes(1) == 1_048_576
    end
  end
end
