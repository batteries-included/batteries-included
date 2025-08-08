defmodule CommonCore.ProtocolTest do
  use ExUnit.Case, async: true

  alias CommonCore.Protocol

  describe "Protocol enum as Ecto.Type" do
    test "casts valid atom protocols" do
      assert Protocol.cast(:http) == {:ok, :http}
      assert Protocol.cast(:http2) == {:ok, :http2}
      assert Protocol.cast(:tcp) == {:ok, :tcp}
    end

    test "casts valid string protocols" do
      assert Protocol.cast("http") == {:ok, :http}
      assert Protocol.cast("http2") == {:ok, :http2}
      assert Protocol.cast("tcp") == {:ok, :tcp}
    end

    test "returns error for invalid protocols" do
      assert Protocol.cast(:invalid) == :error
      assert Protocol.cast("invalid") == :error
      assert Protocol.cast(123) == :error
    end

    test "dumps valid protocols to strings" do
      assert Protocol.dump(:http) == {:ok, "http"}
      assert Protocol.dump(:http2) == {:ok, "http2"}
      assert Protocol.dump(:tcp) == {:ok, "tcp"}
    end

    test "loads valid protocol strings to atoms" do
      assert Protocol.load("http") == {:ok, :http}
      assert Protocol.load("http2") == {:ok, :http2}
      assert Protocol.load("tcp") == {:ok, :tcp}
    end

    test "returns :string as type" do
      assert Protocol.type() == :string
    end
  end

  describe "options/0" do
    test "returns protocol options for forms" do
      options = Protocol.options()

      assert {"HTTP", :http} in options
      assert {"HTTP2", :http2} in options
      assert {"TCP", :tcp} in options

      assert length(options) == 3
    end

    test "all options return atoms as values" do
      options = Protocol.options()

      Enum.each(options, fn {_label, value} ->
        assert is_atom(value)
      end)
    end
  end

  describe "valid_value?/1" do
    test "returns true for valid string values" do
      assert Protocol.valid_value?("http") == true
      assert Protocol.valid_value?("http2") == true
      assert Protocol.valid_value?("tcp") == true
    end

    test "returns false for invalid values" do
      assert Protocol.valid_value?("invalid") == false
      assert Protocol.valid_value?(:http) == false
      assert Protocol.valid_value?(123) == false
    end
  end
end
