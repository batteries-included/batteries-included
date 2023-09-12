defmodule ControlServerWeb.Components.TooltipTest do
  use Heyya.SnapshotTest

  import ControlServerWeb.Tooltip

  component_snapshot_test "default tooltip" do
    assigns = %{}

    ~H"""
    <div id="important">Hoverable</div>
    <.tooltip target_id="important">This is the tootip for something important</.tooltip>
    """
  end

  component_snapshot_test "help question mark with tooltip" do
    assigns = %{}

    ~H"""
    <.help_question_mark id="example_battery_descript">
      Example defintion that convinces people the battery is valuable.
    </.help_question_mark>
    """
  end
end
