defmodule CommonUI.Components.FieldTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.Field

  component_snapshot_test "stacked field component" do
    assigns = %{}

    ~H"""
    <.field>
      <:label>Label</:label>
    </.field>
    """
  end

  component_snapshot_test "beside field component" do
    assigns = %{}

    ~H"""
    <.field variant="beside">
      <:label>Label</:label>
    </.field>
    """
  end

  component_snapshot_test "field component with note and help text" do
    assigns = %{}

    ~H"""
    <.field>
      <:label help="This is some help text">Label</:label>
      <:note>This is a note</:note>
    </.field>
    """
  end
end
