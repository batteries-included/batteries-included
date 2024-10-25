defmodule CommonUI.Components.ListTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.List

  component_snapshot_test "todo list component" do
    assigns = %{}

    ~H"""
    <.list variant="todo">
      <:item completed navigate="/foo">Foo</:item>
      <:item navigate="/bar">Bar</:item>
    </.list>
    """
  end

  component_snapshot_test "check list component" do
    assigns = %{}

    ~H"""
    <.list variant="check">
      <:item>Foo</:item>
      <:item>Bar</:item>
    </.list>
    """
  end
end
