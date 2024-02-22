defmodule Storybook.CommonUI.ClickFlip do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.ClickFlip.click_flip/1

  def attributes, do: []
  def slots, do: []

  def variations,
    do: [
      %Variation{
        id: :default,
        slots: [
          "Main Content",
          """
          <:hidden>
          Inner Content
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
          Inner Content
          </:hidden>
          """
        ]
      }
    ]
end
