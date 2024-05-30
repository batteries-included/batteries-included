defmodule Storybook.Components.Input.Range do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1
  def container, do: {:div, class: "w-full p-4"}

  def variations do
    [
      %Variation{
        id: :range,
        attributes: %{
          type: "range",
          name: "foobar",
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
          show_value: false,
          value: 4,
          step: 1,
          max: 5,
          min: 1
        }
      },
      %Variation{
        id: :with_error,
        attributes: %{
          type: "range",
          name: "foobar",
          show_value: false,
          value: 4,
          step: 1,
          max: 5,
          min: 1,
          errors: ["Oh no"],
          force_feedback: true
        }
      },
      %Variation{
        id: :with_ticks,
        attributes: %{
          type: "range",
          name: "foobar",
          show_value: false,
          value: 50,
          step: 1,
          max: 100,
          ticks: [
            {"0%", 0},
            {"15%", 0.15},
            {"50%", 0.5},
            {"75%", 0.75},
            {"100%", 1}
          ]
        }
      },
      %Variation{
        id: :with_boundaries,
        attributes: %{
          type: "range",
          name: "foobar",
          show_value: false,
          value: 50,
          step: 1,
          max: 100,
          lower_boundary: 15,
          upper_boundary: 75,
          ticks: [
            {"0%", 0},
            {"15%", 0.15},
            {"50%", 0.5},
            {"75%", 0.75},
            {"100%", 1}
          ]
        }
      }
    ]
  end
end
