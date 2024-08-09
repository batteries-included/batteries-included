defmodule Storybook.Components.TodoList do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias CommonUI.Components.TodoList

  def function, do: &TodoList.todo_list/1
  def imports, do: [{TodoList, todo_list_item: 1}]

  def variations do
    [
      %Variation{
        id: :default,
        slots: [
          "<.todo_list_item completed>Item 1</.todo_list_item>",
          "<.todo_list_item>Item 2</.todo_list_item>"
        ]
      }
    ]
  end
end
