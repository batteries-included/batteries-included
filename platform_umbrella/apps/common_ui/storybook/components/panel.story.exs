defmodule Storybook.Components.Panel do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Panel.panel/1

  def imports, do: [{CommonUI.Components.Button, button: 1}]

  def container, do: {:div, class: "psb-p-5"}

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{title: "Title", class: "w-full"},
        slots: [
          ~s"""
          <:menu>
            <.button icon={:plus}>Menu</.button>
          </:menu>

          Content
          """
        ]
      },
      %Variation{
        id: :gray,
        attributes: %{
          title: "Title",
          variant: "gray",
          class: "w-full"
        },
        slots: ["Content"]
      }
    ]
  end
end
