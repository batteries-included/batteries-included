defmodule Storybook.Components.Input.Checkbox do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1

  def variations do
    [
      %Variation{
        id: :checkbox,
        attributes: %{
          type: "checkbox",
          name: "foobar",
          label: "Label",
          checked: true
        }
      },
      %Variation{
        id: :disabled,
        attributes: %{
          type: "checkbox",
          name: "foobar",
          label: "Label",
          checked: false,
          disabled: true
        }
      },
      %Variation{
        id: :with_error,
        attributes: %{
          type: "checkbox",
          name: "foobar",
          label: "Label",
          checked: false,
          errors: ["Oh no"],
          force_feedback: true
        }
      }
    ]
  end
end
