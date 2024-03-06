defmodule CommonUI.Components.PanelTest do
  use Heyya.SnapshotTest

  import CommonUI.Components.Panel

  component_snapshot_test "Panel test" do
    assigns = %{}

    ~H"""
    <.panel>
      Inner test
    </.panel>
    """
  end
end
