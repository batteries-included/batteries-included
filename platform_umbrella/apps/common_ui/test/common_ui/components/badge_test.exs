defmodule CommonUI.Components.BadgeTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Badge

  component_snapshot_test "badge with value" do
    assigns = %{}

    ~H"""
    <.badge label="Foobar" value={5} />
    """
  end

  component_snapshot_test "badge with items" do
    assigns = %{}

    ~H"""
    <.badge>
      <:item label="Foo">Bar</:item>
      <:item label="Baz">Qux</:item>
    </.badge>
    """
  end

  component_snapshot_test "minimal badge" do
    assigns = %{}

    ~H"""
    <.badge minimal label="Foobar" />
    """
  end
end
