defmodule CommonUI.Components.PanelTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Panel

  component_snapshot_test "default panel component" do
    assigns = %{}

    ~H"""
    <.panel title="Foobar">
      Hello
    </.panel>
    """
  end

  component_snapshot_test "gray panel component" do
    assigns = %{}

    ~H"""
    <.panel title="Foobar" variant="gray">
      Hello
    </.panel>
    """
  end

  component_snapshot_test "shadowed panel component" do
    assigns = %{}

    ~H"""
    <.panel title="Foobar" variant="shadowed">
      Hello
    </.panel>
    """
  end

  component_snapshot_test "large title panel component" do
    assigns = %{}

    ~H"""
    <.panel title="Foobar" title_size="lg">
      Hello
    </.panel>
    """
  end
end
