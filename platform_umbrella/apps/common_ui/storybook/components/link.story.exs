defmodule Storybook.Components.Link do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Link.a/1

  def attributes, do: []
  def slots, do: []

  def variations,
    do: [
      %Variation{
        id: :default,
        description: "Default Link",
        attributes: %{variant: "unstyled", navigate: "/"},
        slots: ["Default Link (unstyled)"]
      },
      %Variation{
        id: :styled,
        description: "Styled Link",
        attributes: %{variant: "styled", navigate: "/"},
        slots: ["Link with a tux"]
      },
      %Variation{
        id: :external,
        description: "External",
        attributes: %{variant: "external", href: "https://www.eff.org"},
        slots: ["I'm outta here"]
      }
    ]
end
