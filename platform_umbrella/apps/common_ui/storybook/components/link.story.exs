defmodule Storybook.Components.Link do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Link.a/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{navigate: "/"},
        slots: ["Default Link"]
      },
      %Variation{
        id: :underlined,
        attributes: %{variant: "underlined", navigate: "/"},
        slots: ["Link with underline"]
      },
      %Variation{
        id: :icon,
        attributes: %{variant: "icon", navigate: "/", icon: :face_smile},
        slots: ["I'm outta here"]
      },
      %Variation{
        id: :external,
        attributes: %{variant: "external", href: "https://www.eff.org"},
        slots: ["I'm outta here"]
      },
      %Variation{
        id: :bordered,
        attributes: %{variant: "bordered"},
        slots: ["Bordered Link"]
      },
      %Variation{
        id: :external_bordered,
        attributes: %{variant: "bordered", href: "https://www.eff.org"},
        slots: ["I'm outta here"]
      },
      %Variation{
        id: :bordered_large,
        attributes: %{variant: "bordered-lg", icon: :face_smile},
        slots: ["Be Happy"]
      }
    ]
  end
end
