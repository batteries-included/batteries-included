defmodule CommonUI.TooltipTest do
  use Heyya.SnapshotTest

  import CommonUI.Tooltip

  component_snapshot_test "empty tooltip render" do
    assigns = %{}

    ~H"""
    <.hover_tooltip>this should render totally deviod of any wrappers</.hover_tooltip>
    """
  end

  component_snapshot_test "tooltip render" do
    assigns = %{}

    ~H"""
    <.hover_tooltip>
      <:tooltip>Test</:tooltip>
      Hello
    </.hover_tooltip>
    """
  end

  component_snapshot_test "tooltip with class" do
    assigns = %{}

    ~H"""
    <.hover_tooltip class="underline">
      <:tooltip>Test</:tooltip>
      Underlined text
    </.hover_tooltip>
    """
  end
end
