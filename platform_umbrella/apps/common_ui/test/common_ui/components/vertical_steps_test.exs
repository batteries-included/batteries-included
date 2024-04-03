defmodule CommonUI.Components.VerticalStepsTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.VerticalSteps

  component_snapshot_test "Vertical steps" do
    assigns = %{}

    ~H"""
    <.vertical_steps current_step={1}>
      <:step>Step 0</:step>
      <:step>Step 1</:step>
      <:step>Step 2</:step>
    </.vertical_steps>
    """
  end

  component_snapshot_test "Vertical steps no steps completed" do
    assigns = %{}

    ~H"""
    <.vertical_steps current_step={-1}>
      <:step>Step 0</:step>
      <:step>Step 1</:step>
      <:step>Step 2</:step>
    </.vertical_steps>
    """
  end
end
