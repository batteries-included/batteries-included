defmodule CommonUI.Components.FormTest do
  use Heyya.SnapshotTest

  import CommonUI.Components.Form

  component_snapshot_test "stepped form" do
    assigns = %{}

    ~H"""
    <.simple_form variant="stepped" title="Some title" description="Some description">
      <div>Some inputs would go here</div>

      <:actions>
        <div>Some actions would go here</div>
      </:actions>
    </.simple_form>
    """
  end

  component_snapshot_test "nested form" do
    assigns = %{}

    ~H"""
    <.simple_form variant="nested">
      <div>Some inputs would go here</div>

      <:actions>
        <div>Some actions would go here</div>
      </:actions>
    </.simple_form>
    """
  end
end
