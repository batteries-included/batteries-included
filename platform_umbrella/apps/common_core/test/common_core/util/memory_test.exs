defmodule CommonCore.Util.MemoryTest do
  use ExUnit.Case

  import CommonCore.Util.Memory

  describe "to_bytes/2" do
    test "formats from B" do
      assert to_bytes("999B") == 999
      assert to_bytes(999, :B) == 999
    end

    test "formats from KB" do
      assert to_bytes("1KB") == 1024
      assert to_bytes("1.0KB") == 1024
      assert to_bytes(1, :KB) == 1024
    end

    test "formats from MB" do
      assert to_bytes("1MB") == 1_048_576
      assert to_bytes(1, :MB) == 1_048_576
    end

    test "formats from GB" do
      assert to_bytes("1GB") == 1_073_741_824
      assert to_bytes(1, :GB) == 1_073_741_824
    end

    test "formats from TB" do
      assert to_bytes("1TB") == 1_099_511_627_776
      assert to_bytes("1.0TB") == 1_099_511_627_776
      assert to_bytes(1, :TB) == 1_099_511_627_776
    end

    test "returns error for invalid string" do
      assert to_bytes("foobar") == :error
    end
  end

  describe "from_bytes/2" do
    test "formats to B" do
      assert from_bytes(1, :B) == 1.0
      assert from_bytes(1_000_000, :B) == 1_000_000.0
    end

    test "formats to KB" do
      assert from_bytes(1024, :KB) == 1.0
      assert from_bytes(1_048_576, :KB) == 1024.0
    end

    test "formats to MB" do
      assert from_bytes(1_048_576, :MB) == 1.0
      assert from_bytes(1_073_741_824, :MB) == 1024.0
      assert from_bytes(1_099_511_627_776, :MB) == 1_048_576.0
    end

    test "formats to GB" do
      assert from_bytes(1_073_741_824, :GB) == 1.0
      assert from_bytes(1_099_511_627_776, :GB) == 1024.0
    end

    test "formats to TB" do
      assert from_bytes(1_099_511_627_776, :TB) == 1.0
    end
  end

  describe "humanize/2" do
    test "handles nil input" do
      assert humanize(nil) == "0B"
      assert humanize("") == "0B"
    end

    test "handles binary input" do
      assert humanize("1024") == "1.0KB"
    end

    test "formats to B" do
      assert humanize(999) == "999B"
    end

    test "formats to KB" do
      assert humanize(1024) == "1.0KB"
      assert humanize(1024, false) == "1KB"
    end

    test "formats to MB" do
      assert humanize(1_572_864) == "2MB"
    end

    test "formats to GB" do
      assert humanize(137_438_953_472) == "128GB"
    end

    test "formats to TB" do
      assert humanize(1_099_511_627_776) == "1.0TB"
      assert humanize(3_839_143_349_769, false) == "3TB"
    end
  end

  describe "bytes_as_select_options/1" do
    test "generates select options" do
      options = [1024, 1_048_576]
      assert bytes_as_select_options(options) == [{"1KB", 1024}, {"1MB", 1_048_576}]
    end
  end

  describe "range_value_to_bytes/2" do
    test "should return relative bytes from range value" do
      ticks = [{"1GB", 0}, {"10GB", 0.4}, {"500GB", 0.6}, {"1TB", 1}]

      assert range_value_to_bytes(0, ticks) == to_bytes(1, :GB)
      assert range_value_to_bytes(to_bytes(1, :GB), ticks) == to_bytes(1, :GB)
      assert range_value_to_bytes(to_bytes(0.2, :TB), ticks) == to_bytes(5.5, :GB)
      assert range_value_to_bytes(to_bytes(0.4, :TB), ticks) == to_bytes(10, :GB)
      assert range_value_to_bytes(to_bytes(0.5, :TB), ticks) == to_bytes(255, :GB)

      # why does `to_bytes(500, :GB)` cause a rounding issue?
      assert range_value_to_bytes(to_bytes(0.6, :TB), ticks) == 536_870_912_001

      assert range_value_to_bytes(to_bytes(0.8, :TB), ticks) == to_bytes(762, :GB)
      assert range_value_to_bytes(to_bytes(1, :TB), ticks) == to_bytes(1, :TB)
    end

    test "should return relative bytes from range value with inset ticks" do
      ticks = [{"1GB", 0.3}, {"500GB", 0.5}, {"1TB", 0.8}]

      assert range_value_to_bytes(0, ticks) == 0
      assert range_value_to_bytes(to_bytes(0.1875, :TB), ticks) == to_bytes(512, :MB)
      assert range_value_to_bytes(to_bytes(0.375, :TB), ticks) == to_bytes(1, :GB)
      assert range_value_to_bytes(to_bytes(0.5, :TB), ticks) == to_bytes(250.5, :GB)
      assert range_value_to_bytes(to_bytes(0.625, :TB), ticks) == to_bytes(500, :GB)
      assert range_value_to_bytes(to_bytes(0.8125, :TB), ticks) == to_bytes(762, :GB)
      assert range_value_to_bytes(to_bytes(1, :TB), ticks) == to_bytes(1, :TB)
      assert range_value_to_bytes(to_bytes(1.125, :TB), ticks) == to_bytes(1.125, :TB)
      assert range_value_to_bytes(to_bytes(1.25, :TB), ticks) == to_bytes(1.25, :TB)
    end

    test "should return relative bytes from range value with single tick" do
      ticks = [{"500GB", 0.5}]

      assert range_value_to_bytes(0, ticks) == 0
      assert range_value_to_bytes(to_bytes(250, :GB), ticks) == to_bytes(250, :GB)
      assert range_value_to_bytes(to_bytes(500, :GB), ticks) == to_bytes(500, :GB)
      assert range_value_to_bytes(to_bytes(750, :GB), ticks) == to_bytes(750, :GB)
      assert range_value_to_bytes(to_bytes(1000, :GB), ticks) == to_bytes(1000, :GB)
    end

    test "should return error when out of bounds" do
      ticks = [{"1B", 0}, {"99B", 1}]

      assert range_value_to_bytes(-1, ticks) == :error
      assert range_value_to_bytes(100, ticks) == :error
    end
  end

  describe "bytes_to_range_value/2" do
    test "should return range value from relative bytes" do
      ticks = [{"1GB", 0}, {"10GB", 0.4}, {"500GB", 0.6}, {"1TB", 1}]

      assert bytes_to_range_value(to_bytes(1, :GB), ticks) == to_bytes(1, :GB)
      assert bytes_to_range_value(to_bytes(5.5, :GB), ticks) == to_bytes(0.2, :TB)
      assert bytes_to_range_value(to_bytes(10, :GB), ticks) == to_bytes(0.4, :TB)
      assert bytes_to_range_value(to_bytes(255, :GB), ticks) == to_bytes(0.5, :TB)
      assert bytes_to_range_value(to_bytes(500, :GB), ticks) == to_bytes(0.6, :TB)
      assert bytes_to_range_value(to_bytes(762, :GB), ticks) == to_bytes(0.8, :TB)
      assert bytes_to_range_value(to_bytes(1, :TB), ticks) == to_bytes(1, :TB)
    end

    test "should return range value with inset ticks from relative bytes" do
      ticks = [{"1GB", 0.3}, {"500GB", 0.5}, {"1TB", 0.8}]

      assert bytes_to_range_value(0, ticks) == 0
      assert bytes_to_range_value(to_bytes(512, :MB), ticks) == to_bytes(0.1875, :TB)
      assert bytes_to_range_value(to_bytes(1, :GB), ticks) == to_bytes(0.375, :TB)
      assert bytes_to_range_value(to_bytes(250.5, :GB), ticks) == to_bytes(0.5, :TB)
      assert bytes_to_range_value(to_bytes(500, :GB), ticks) == to_bytes(0.625, :TB)
      assert bytes_to_range_value(to_bytes(762, :GB), ticks) == to_bytes(0.8125, :TB)
      assert bytes_to_range_value(to_bytes(1, :TB), ticks) == to_bytes(1, :TB)
      assert bytes_to_range_value(to_bytes(1.125, :TB), ticks) == to_bytes(1.125, :TB)
      assert bytes_to_range_value(to_bytes(1.25, :TB), ticks) == to_bytes(1.25, :TB)
    end

    test "should return range value with single tick from relative bytes" do
      ticks = [{"500GB", 0.5}]

      assert bytes_to_range_value(0, ticks) == 0
      assert bytes_to_range_value(to_bytes(250, :GB), ticks) == to_bytes(250, :GB)
      assert bytes_to_range_value(to_bytes(500, :GB), ticks) == to_bytes(500, :GB)
      assert bytes_to_range_value(to_bytes(750, :GB), ticks) == to_bytes(750, :GB)
      assert bytes_to_range_value(to_bytes(1000, :GB), ticks) == to_bytes(1000, :GB)
    end

    test "should return nil when passed nil" do
      ticks = [{"500GB", 0.5}]

      assert bytes_to_range_value(nil, ticks) == nil
    end

    test "should return error when out of bounds" do
      ticks = [{"1B", 0}, {"99B", 1}]

      assert bytes_to_range_value(0, ticks) == 0
      assert bytes_to_range_value(100, ticks) == 99
    end
  end

  describe "min_range_value/1" do
    test "should get the minimum value" do
      assert min_range_value([{"1GB", 0}, {"2GB", 1}]) == to_bytes(1, :GB)
    end

    test "should calculate the minimum value" do
      assert min_range_value([{"1GB", 0.1}, {"2GB", 1}]) == 0
      assert min_range_value([{"1GB", 0.5}]) == 0
    end
  end

  describe "max_range_value/1" do
    test "should get the maximum value" do
      assert max_range_value([{"1GB", 0}, {"2GB", 1}]) == to_bytes(2, :GB)
    end

    test "should calculate the maximum value" do
      assert max_range_value([{"1GB", 0}, {"2GB", 0.8}]) == to_bytes(2.5, :GB)
      assert max_range_value([{"1GB", 0.5}]) == to_bytes(2, :GB)
    end
  end
end
