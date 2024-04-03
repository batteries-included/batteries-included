defmodule Storybook.Components.Input.Range do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1
  def container, do: {:div, class: "w-full"}

  def variations do
    [
      %Variation{
        id: :range,
        attributes: %{
          type: "range",
          name: "foobar",
          label: "Label",
          value: 2,
          step: 1,
          max: 5,
          min: 1
        }
      },
      %Variation{
        id: :without_value,
        attributes: %{
          type: "range",
          name: "foobar",
          label: "Label",
          show_value: false,
          value: 4,
          step: 1,
          max: 5,
          min: 1
        }
      }
    ]
  end
end
