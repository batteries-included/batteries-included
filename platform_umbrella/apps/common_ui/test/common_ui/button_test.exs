defmodule CommonUI.ButtonTest do
  use CommonTesting.ComponentSnapshotTest

  import CommonUI.Button

  component_snapshot_test "default button" do
    assigns = %{}

    ~H"""
    <.button>Test Button</.button>
    """
  end
end
