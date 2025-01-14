defmodule CommonCore.Batteries.CatalogTest do
  use ExUnit.Case, async: true

  import CommonCore.Batteries.Catalog

  alias CommonCore.Batteries.CatalogBattery
  alias CommonCore.Batteries.CatalogGroup

  test "groups/0" do
    assert [%CatalogGroup{} | _] = groups()
  end

  test "groups_for_projects/0" do
    refute Enum.any?(groups_for_projects(), &(&1.type == :magic))
  end

  describe "group/1" do
    test "should get group with string" do
      assert %CatalogGroup{type: :magic} = group("magic")
    end

    test "should get group" do
      assert %CatalogGroup{type: :magic} = group(:magic)
    end
  end

  describe "all/0" do
    test "should get all batteries" do
      assert [%CatalogBattery{} | _] = all()
    end

    test "should make sure all batteries are in a valid group" do
      for battery <- all(), do: assert(group(battery.group))
    end
  end

  test "all/1" do
    assert [%CatalogBattery{group: :magic} | _] = all(:magic)
  end

  describe "all_for_usage" do
    test "all_for_usage/1" do
      assert all() == all_for_usage(:internal_dev)
      assert [] == all_for_usage(:not_a_real_usage)
    end

    test "all_for_usage/2" do
      assert [%CatalogBattery{group: :magic} | _] = all_for_usage(:internal_dev, :magic)
      assert [] == all_for_usage(:not_a_real_usage, :magic)
    end
  end

  describe "get/1" do
    test "should get battery with string" do
      assert %CatalogBattery{type: :timeline} = get("timeline")
    end

    test "should get battery" do
      assert %CatalogBattery{type: :timeline} = get(:timeline)
    end
  end

  describe "get_recursive/1" do
    test "should get batteries with atom" do
      assert [%CatalogBattery{type: :battery_core}, %CatalogBattery{type: :timeline}] =
               get_recursive(:timeline)
    end

    test "should get batteries" do
      assert [%CatalogBattery{type: :battery_core}, %CatalogBattery{type: :timeline}] =
               :timeline |> get() |> get_recursive()
    end
  end

  test "battery_type_map/0" do
    assert %{timeline: %CatalogBattery{type: :timeline}} = battery_type_map()
  end
end
