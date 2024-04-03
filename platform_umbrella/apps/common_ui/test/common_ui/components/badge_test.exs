defmodule CommonUI.Components.BadgeTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Badge

  describe "badge component" do
    component_snapshot_test "with value" do
      assigns = %{}

      ~H"""
      <.badge label="Foobar" value={5} />
      """
    end

    component_snapshot_test "with items" do
      assigns = %{}

      ~H"""
      <.badge>
        <:item label="Foo">Bar</:item>
        <:item label="Baz">Qux</:item>
      </.badge>
      """
    end
  end
end
