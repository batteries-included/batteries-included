defmodule CommonUI.Components.ButtonTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Button

  component_snapshot_test "default button" do
    assigns = %{}

    ~H"""
    <.button>Test Button</.button>
    """
  end
end
