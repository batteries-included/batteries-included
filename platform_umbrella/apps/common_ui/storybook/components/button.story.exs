defmodule Storybook.Components.Button do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Button.button/1

  def attributes do
    [
      %Attr{
        id: :disabled,
        type: :boolean,
        required: false,
        default: false
      }
    ]
  end

  def variations do
    [
      %Variation{
        id: :default,
        slots: ["Default Button"]
      },
      %VariationGroup{
        id: :minimal,
        variations: [
          %Variation{
            id: :minimal_button,
            slots: ["Minimal Button"],
            attributes: %{
              variant: "minimal"
            }
          },
          %Variation{
            id: :minimal_icon,
            attributes: %{
              variant: "minimal",
              icon: :trash
            }
          }
        ]
      },
      %Variation{
        id: :primary,
        slots: ["Primary Button"],
        attributes: %{
          variant: "primary"
        }
      },
      %Variation{
        id: :secondary,
        slots: ["Secondary Button"],
        attributes: %{
          variant: "secondary",
          icon: :cube
        }
      },
      %Variation{
        id: :dark,
        slots: ["Dark Button"],
        attributes: %{
          variant: "dark",
          icon: :plus
        }
      },
      %Variation{
        id: :danger,
        slots: ["Danger Button"],
        attributes: %{
          variant: "danger"
        }
      },
      %Variation{
        id: :icon,
        attributes: %{
          variant: "icon",
          icon: :trash
        }
      },
      %Variation{
        id: :icon_bordered,
        attributes: %{
          variant: "icon_bordered",
          icon: :arrow_left
        }
      },
      %Variation{
        id: :internal_link,
        slots: ["Internal Link"],
        attributes: %{
          icon: :arrow_right,
          icon_position: :right,
          link: "/_"
        }
      },
      %Variation{
        id: :external_link,
        slots: ["External Link"],
        attributes: %{
          icon: :arrow_top_right_on_square,
          icon_position: :right,
          link: "https://www.batteriesincl.com",
          link_type: "external",
          target: "_blank"
        }
      }
    ]
  end
end
