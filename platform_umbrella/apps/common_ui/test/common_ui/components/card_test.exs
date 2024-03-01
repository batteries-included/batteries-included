defmodule CommonUI.Components.CardTest do
  use Heyya.SnapshotTest

  import CommonUI.Components.Card

  component_snapshot_test "Card test" do
    assigns = %{}

    ~H"""
    <.card>
      Inner test
    </.card>
    """
  end
end
