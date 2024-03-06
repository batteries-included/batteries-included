defmodule Storybook.Components.ClickFlip do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.ClickFlip.click_flip/1

  def variations,
    do: [
      %Variation{
        id: :default,
        slots: [
          "Main Content",
          """
          <:hidden>
          <input class="w-full rounded-md border-1" placeholder="Example Input" />
          </:hidden>
          """
        ]
      },
      %Variation{
        id: :styled,
        attributes: %{cursor_class: "cursor-text", content_class: "p-8"},
        slots: [
          "Lots of Padding Here",
          """
          <:hidden>
          <input class="w-full rounded-md border-1" placeholder="Example Input" />
          </:hidden>
          """
        ]
      }
    ]
end
