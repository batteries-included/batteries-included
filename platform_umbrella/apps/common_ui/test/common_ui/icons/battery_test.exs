defmodule CommonUI.Icons.BatteryTest do
  use Heyya.SnapshotTest

  import CommonUI.Icons.Battery

  component_snapshot_test "Battery Icon" do
    assigns = %{}

    ~H"""
    <.icon />
    """
  end
end
