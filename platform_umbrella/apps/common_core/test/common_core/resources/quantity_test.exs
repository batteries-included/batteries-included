defmodule CommonCore.Resources.QuantityTest do
  use ExUnit.Case

  import CommonCore.Resources.Quantity, only: [parse_quantity: 1]

  describe "Quantity.parse_quantity/1" do
    test "integers pass through" do
      assert parse_quantity("1") == 1
      assert parse_quantity("900") == 900
      assert parse_quantity("1000") == 1000
    end

    test "1Ki" do
      assert parse_quantity("1Ki") == 1024
    end

    test "1Mi" do
      assert parse_quantity("1Mi") == 1024 * 1024
    end

    test "420Mi" do
      assert parse_quantity("420Mi") == 420 * 1024 * 1024
    end

    test "1Gi" do
      assert parse_quantity("1Gi") == 1024 * 1024 * 1024
    end

    test "69Gi" do
      assert parse_quantity("69Gi") == 69 * 1024 * 1024 * 1024
    end

    test "1Ti" do
      assert parse_quantity("1Ti") == 1024 * 1024 * 1024 * 1024
    end

    test "1Pi" do
      assert parse_quantity("1Pi") == 1024 * 1024 * 1024 * 1024 * 1024
    end

    test "1Ei" do
      assert parse_quantity("1Ei") == 1024 * 1024 * 1024 * 1024 * 1024 * 1024
    end

    test "1n" do
      assert parse_quantity("1n") == 0.000000001
    end

    test "1u" do
      assert parse_quantity("1u") == 0.000001
    end

    test "1m" do
      assert parse_quantity("1m") == 0.001
    end

    test "500m" do
      assert parse_quantity("500m") == 0.5
    end

    test "1k" do
      assert parse_quantity("1k") == 1000
    end

    test "1M" do
      assert parse_quantity("1M") == 1000 * 1000
    end

    test "500M" do
      assert parse_quantity("500M") == 500 * 1000 * 1000
    end

    test "1G" do
      assert parse_quantity("1G") == 1000 * 1000 * 1000
    end
  end
end
