defmodule CommonCore.Util.MemoryTest do
  use ExUnit.Case

  alias CommonCore.Util.Memory

  describe "to_bytes/2" do
    test "formats from B" do
      assert Memory.to_bytes("999B") == 999
      assert Memory.to_bytes(999, :B) == 999
    end

    test "formats from KB" do
      assert Memory.to_bytes("1KB") == 1024
      assert Memory.to_bytes("1.0KB") == 1024
      assert Memory.to_bytes(1, :KB) == 1024
    end

    test "formats from MB" do
      assert Memory.to_bytes("1MB") == 1_048_576
      assert Memory.to_bytes(1, :MB) == 1_048_576
    end

    test "formats from GB" do
      assert Memory.to_bytes("1GB") == 1_073_741_824
      assert Memory.to_bytes(1, :GB) == 1_073_741_824
    end

    test "formats from TB" do
      assert Memory.to_bytes("1TB") == 1_099_511_627_776
      assert Memory.to_bytes("1.0TB") == 1_099_511_627_776
      assert Memory.to_bytes(1, :TB) == 1_099_511_627_776
    end

    test "returns error for invalid string" do
      assert Memory.to_bytes("foobar") == :error
    end
  end

  describe "from_bytes/2" do
    test "formats to B" do
      assert Memory.from_bytes(1, :B) == 1.0
      assert Memory.from_bytes(1_000_000, :B) == 1_000_000.0
    end

    test "formats to KB" do
      assert Memory.from_bytes(1024, :KB) == 1.0
      assert Memory.from_bytes(1_048_576, :KB) == 1024.0
    end

    test "formats to MB" do
      assert Memory.from_bytes(1_048_576, :MB) == 1.0
      assert Memory.from_bytes(1_073_741_824, :MB) == 1024.0
      assert Memory.from_bytes(1_099_511_627_776, :MB) == 1_048_576.0
    end

    test "formats to GB" do
      assert Memory.from_bytes(1_073_741_824, :GB) == 1.0
      assert Memory.from_bytes(1_099_511_627_776, :GB) == 1024.0
    end

    test "formats to TB" do
      assert Memory.from_bytes(1_099_511_627_776, :TB) == 1.0
    end
  end

  describe "humanize/2" do
    test "handles nil input" do
      assert Memory.humanize(nil) == nil
    end

    test "handles binary input" do
      assert Memory.humanize("1024") == "1.0KB"
    end

    test "formats to B" do
      assert Memory.humanize(999) == "999B"
    end

    test "formats to KB" do
      assert Memory.humanize(1024) == "1.0KB"
      assert Memory.humanize(1024, false) == "1KB"
    end

    test "formats to MB" do
      assert Memory.humanize(1_572_864) == "2MB"
    end

    test "formats to GB" do
      assert Memory.humanize(137_438_953_472) == "128GB"
    end

    test "formats to TB" do
      assert Memory.humanize(1_099_511_627_776) == "1.0TB"
      assert Memory.humanize(3_839_143_349_769, false) == "3TB"
    end
  end

  describe "bytes_as_select_options/1" do
    test "generates select options" do
      options = [1024, 1_048_576]
      assert Memory.bytes_as_select_options(options) == [{"1KB", 1024}, {"1MB", 1_048_576}]
    end
  end
end
