defmodule Storybook.Components.Input.Checkbox do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1
  def imports, do: [{CommonUI.Components.Field, field: 1}]

  def variations do
    [
      %Variation{
        id: :checkbox,
        attributes: %{
          type: "checkbox",
          name: "foobar",
          checked: true
        }
      },
      %Variation{
        id: :disabled,
        attributes: %{
          type: "checkbox",
          name: "foobar",
          checked: false,
          disabled: true
        }
      },
      %Variation{
        id: :inline_label,
        attributes: %{
          type: "checkbox",
          name: "foobar",
          checked: false
        },
        slots: [
          "Inline Label"
        ]
      },
      %Variation{
        id: :with_error,
        attributes: %{
          type: "checkbox",
          name: "foobar",
          checked: false,
          errors: ["Oh no"],
          force_feedback: true
        },
        template: """
        <.field variant="beside">
          <:label>Label</:label>
          <.psb-variation />
        </.field>
        """
      }
    ]
  end
end
