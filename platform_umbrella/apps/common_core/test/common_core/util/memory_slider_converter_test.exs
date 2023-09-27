defmodule CommonCore.Util.MemorySliderConverterTest do
  use ExUnit.Case

  alias CommonCore.Util.Memory
  alias CommonCore.Util.MemorySliderConverter

  describe "slider_value_to_bytes/1" do
    test "converts the lower bound correctly" do
      assert MemorySliderConverter.slider_value_to_bytes(1) == Memory.gb_to_bytes(128)
    end

    test "converts the upper bound correctly" do
      assert MemorySliderConverter.slider_value_to_bytes(256) == Memory.gb_to_bytes(4096)
    end
  end

  describe "bytes_to_slider_value/1" do
    test "converts the lower bound correctly" do
      bytes = Memory.gb_to_bytes(128)
      assert MemorySliderConverter.bytes_to_slider_value(bytes) == 1
    end

    test "converts the upper bound correctly" do
      bytes = Memory.gb_to_bytes(4096)
      assert MemorySliderConverter.bytes_to_slider_value(bytes) == 256
    end
  end
end
