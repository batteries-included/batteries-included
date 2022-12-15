defmodule CommonUI.CardTest do
  use Heyya

  import CommonUI.Card

  component_snapshot_test "Card test" do
    assigns = %{}

    ~H"""
    <.card>
      Inner test
    </.card>
    """
  end
end
