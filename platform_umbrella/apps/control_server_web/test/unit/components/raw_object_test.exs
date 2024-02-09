defmodule ControlServerWeb.Components.RawObjectTest do
  use Heyya.SnapshotTest

  import ControlServerWeb.ObjectDisplay

  @easy_map %{"a" => 1, "b" => 2, "c" => 3}
  @deep_map %{"a" => %{"b" => %{"c" => 3}, "d" => 4}, "e" => 5, "f" => 6}
  @map_with_array %{"a" => [1, 2, 3], "b" => [4, 5, 6], "c" => [7, 8, 9]}

  describe "object_display/1 works with map based objects" do
    component_snapshot_test "easy map" do
      assigns = %{object: @easy_map}

      ~H"""
      <.object_display object={@object} path={[]} />
      """
    end

    component_snapshot_test "easy map with path" do
      assigns = %{object: @easy_map, path: ["a"]}

      ~H"""
      <.object_display object={@object} path={@path} />
      """
    end

    component_snapshot_test "deep map" do
      assigns = %{object: @deep_map}

      ~H"""
      <.object_display object={@object} path={[]} />
      """
    end

    component_snapshot_test "deep_map with path" do
      assigns = %{object: @deep_map, path: ["a", "b"]}

      ~H"""
      <.object_display object={@object} path={@path} />
      """
    end

    component_snapshot_test "map with array" do
      assigns = %{object: @map_with_array}

      ~H"""
      <.object_display object={@object} path={[]} />
      """
    end

    component_snapshot_test "map with array with path" do
      assigns = %{object: @map_with_array, path: ["a"]}

      ~H"""
      <.object_display object={@object} path={@path} />
      """
    end

    component_snapshot_test "map with array with selected" do
      assigns = %{object: @map_with_array, path: ["a", "0"]}

      ~H"""
      <.object_display object={@object} path={@path} />
      """
    end
  end
end
