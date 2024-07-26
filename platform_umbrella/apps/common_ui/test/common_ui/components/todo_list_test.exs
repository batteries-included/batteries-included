defmodule CommonUI.Components.TodoListTest do
  use Heyya.SnapshotCase

  import CommonUI.Components.TodoList

  component_snapshot_test "default todo list component" do
    assigns = %{}

    ~H"""
    <.todo_list>
      <.todo_list_item completed navigate="/foo">Foo</.todo_list_item>
      <.todo_list_item navigate="/bar">Bar</.todo_list_item>
    </.todo_list>
    """
  end
end
