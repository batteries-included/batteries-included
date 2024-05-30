defmodule CommonCore.Util.MemorySliderConverterTest do
  use ExUnit.Case

  alias CommonCore.Util.Memory
  alias CommonCore.Util.MemorySliderConverter

  describe "slider_value_to_bytes/1" do
    test "converts the lower bound correctly" do
      assert MemorySliderConverter.slider_value_to_bytes(1) == Memory.to_bytes(128, :MB)
    end

    test "converts the upper bound correctly" do
      assert MemorySliderConverter.slider_value_to_bytes(120) == Memory.to_bytes(4096, :GB)
    end
  end

  describe "bytes_to_slider_value/1" do
    test "converts the lower bound correctly" do
      bytes = Memory.to_bytes(128, :MB)
      assert MemorySliderConverter.bytes_to_slider_value(bytes) == 1
    end

    test "converts the upper bound correctly" do
      bytes = Memory.to_bytes(4096, :GB)
      assert MemorySliderConverter.bytes_to_slider_value(bytes) == 120
    end
  end
end
