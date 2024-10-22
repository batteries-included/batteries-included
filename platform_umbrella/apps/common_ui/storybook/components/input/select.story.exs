defmodule Storybook.Components.Input.Select do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1
  def imports, do: [{CommonUI.Components.Field, field: 1}]
  def container, do: {:div, class: "w-full"}

  def variations do
    [
      %Variation{
        id: :select,
        attributes: %{
          type: "select",
          name: "foobar",
          value: "",
          placeholder: "Choose an option",
          options: [Foo: "foo", Bar: "bar"]
        }
      },
      %Variation{
        id: :multiple,
        attributes: %{
          type: "select",
          name: "foobar",
          value: "",
          options: [Foo: "foo", Bar: "bar"],
          multiple: true
        },
        template: """
        <.field>
          <.psb-variation />
          <:note>Hold down control or command to select multiple</:note>
        </.field>
        """
      },
      %Variation{
        id: :disabled,
        attributes: %{
          type: "select",
          name: "foobar",
          value: "",
          placeholder: "Choose an option",
          options: [Foo: "foo", Bar: "bar"],
          disabled: true
        }
      },
      %Variation{
        id: :with_error,
        attributes: %{
          type: "select",
          name: "foobar",
          value: "",
          placeholder: "Choose an option",
          options: [Foo: "foo", Bar: "bar"],
          errors: ["Something went wrong"],
          force_feedback: true
        }
      }
    ]
  end
end
