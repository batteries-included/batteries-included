defmodule Storybook.Components.Input.Switch do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1
  def imports, do: [{CommonUI.Components.Field, field: 1}]

  def variations do
    [
      %Variation{
        id: :switch,
        attributes: %{
          type: "switch",
          name: "foo",
          value: "false",
          checked: false
        }
      },
      %Variation{
        id: :disabled,
        attributes: %{
          type: "switch",
          name: "foo",
          value: "bar",
          checked: true,
          disabled: true
        }
      },
      %Variation{
        id: :with_error,
        attributes: %{
          type: "switch",
          name: "foo",
          value: "bar",
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
