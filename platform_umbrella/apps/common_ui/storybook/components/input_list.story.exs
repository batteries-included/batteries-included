defmodule Storybook.Components.InputList do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.InputList.input_list/1
  def imports, do: [{CommonUI.Components.Input, input: 1}]

  def variations do
    [
      %Variation{
        id: :default,
        let: :f,
        attributes: %{
          add_label: "Add an item",
          field: %Phoenix.HTML.FormField{
            id: "foobar",
            errors: [],
            field: "foo",
            name: "foo",
            value: ["bar"],
            form: %Phoenix.HTML.Form{}
          }
        },
        slots: [
          """
          <.input field={f} placeholder="Enter a value" />
          """
        ]
      }
    ]
  end
end
