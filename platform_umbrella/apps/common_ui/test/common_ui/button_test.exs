defmodule CommonUI.ButtonTest do
  use Heyya

  import CommonUI.Button

  component_snapshot_test "default button" do
    assigns = %{}

    ~H"""
    <.button>Test Button</.button>
    """
  end

  component_snapshot_test "filled button" do
    assigns = %{}

    ~H"""
    <.button variant="filled">Test Filled Button</.button>
    """
  end
end
