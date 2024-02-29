defmodule Storybook.Components.Button do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Button.button/1

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
        slots: ["Default Button"],
        attributes: %{
          icon: :arrow_top_right_on_square,
          icon_position: :right
        }
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
        id: :circle,
        attributes: %{
          variant: "circle",
          icon: :arrow_right
        }
      },
      %Variation{
        id: :icon,
        attributes: %{
          variant: "icon",
          icon: :trash
        }
      }
    ]
  end
end
