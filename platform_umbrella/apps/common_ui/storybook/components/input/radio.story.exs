defmodule Storybook.Components.Input.Radio do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1
  def imports, do: [{CommonUI.Components.Field, field: 1}]

  def variations do
    [
      %Variation{
        id: :radio,
        attributes: %{
          type: "radio",
          name: "foobar",
          value: ""
        },
        slots: [
          ~s|<:option value="foo">Foo</:option>|,
          ~s|<:option value="bar">Bar</:option>|
        ]
      },
      %Variation{
        id: :disabled,
        attributes: %{
          type: "radio",
          name: "foobar",
          value: "",
          disabled: true
        },
        slots: [
          ~s|<:option value="foo">Foo</:option>|,
          ~s|<:option value="bar">Bar</:option>|
        ]
      },
      %Variation{
        id: :with_error,
        attributes: %{
          type: "radio",
          name: "foobar",
          value: "",
          errors: ["Oh no"],
          force_feedback: true
        },
        template: """
        <.field variant="beside">
          <:label>Label</:label>
          <.psb-variation />
        </.field>
        """,
        slots: [
          ~s|<:option value="foo">Foo</:option>|,
          ~s|<:option value="bar">Bar</:option>|
        ]
      }
    ]
  end
end
