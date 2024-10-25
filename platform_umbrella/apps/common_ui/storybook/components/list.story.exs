defmodule Storybook.Components.List do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias CommonUI.Components.List

  def function, do: &List.list/1

  def variations do
    [
      %Variation{
        id: :todo,
        attributes: %{
          variant: "todo"
        },
        slots: [
          ~s|<:item href="#" completed>Item 1</:item>|,
          ~s|<:item href="#">Item 2</:item>|,
          ~s|<:item href="#">Item 3</:item>|
        ]
      },
      %Variation{
        id: :check,
        attributes: %{
          variant: "check"
        },
        slots: [
          ~s|<:item>Item 1</:item>|,
          ~s|<:item>Item 2</:item>|,
          ~s|<:item>Item 3</:item>|
        ]
      }
    ]
  end
end
