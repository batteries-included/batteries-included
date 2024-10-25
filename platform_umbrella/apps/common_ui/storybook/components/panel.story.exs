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
        attributes: %{title: "Title"},
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
          variant: "gray"
        },
        slots: ["Content"]
      },
      %Variation{
        id: :shadowed,
        attributes: %{
          title: "Title",
          variant: "shadowed"
        },
        slots: ["Content"]
      },
      %Variation{
        id: :larger_title,
        attributes: %{
          title: "Title",
          title_size: "lg",
          variant: "shadowed"
        },
        slots: ["Content"]
      }
    ]
  end
end
