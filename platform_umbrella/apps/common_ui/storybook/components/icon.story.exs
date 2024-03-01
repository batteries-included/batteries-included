defmodule Storybook.Components.Icon do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Icon.icon/1

  def variations do
    [
      %VariationGroup{
        id: :hero,
        description: "Heroicons",
        variations: [
          %Variation{
            id: :hero_outline,
            attributes: %{
              name: :cube,
              class: "size-8"
            }
          },
          %Variation{
            id: :hero_solid,
            attributes: %{
              name: :cube,
              solid: true,
              class: "size-8"
            }
          }
        ]
      },
      %VariationGroup{
        id: :custom,
        description: "Custom icons",
        variations: [
          %Variation{
            id: :custom_battery,
            attributes: %{
              name: :battery,
              class: "size-8"
            }
          }
        ]
      }
    ]
  end
end
