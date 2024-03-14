defmodule Storybook.Components.Input do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1
  def container, do: {:div, class: "w-full"}

  def template do
    """
    <div class="m-5" psb-code-hidden>
      <.psb-variation />
    </div>
    """
  end

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          name: "foobar",
          value: "",
          label: "Label",
          note: "Note"
        }
      },
      %Variation{
        id: :with_icon,
        attributes: %{
          name: "foobar",
          value: "",
          placeholder: "Placeholder",
          icon: :magnifying_glass
        }
      },
      %Variation{
        id: :with_error,
        attributes: %{
          name: "foobar",
          value: "",
          label: "Label",
          errors: ["Something went wrong"],
          force_feedback: true
        }
      },
      %Variation{
        id: :textarea,
        attributes: %{
          type: "textarea",
          name: "foobar",
          value: "",
          label: "Label",
          rows: 3
        }
      },
      %Variation{
        id: :select,
        attributes: %{
          type: "select",
          name: "foobar",
          value: "",
          label: "Label",
          placeholder: "Choose an option",
          options: [Foo: "foo", Bar: "bar"]
        }
      },
      %Variation{
        id: :select_multiple,
        attributes: %{
          type: "select",
          name: "foobar",
          value: "",
          label: "Label",
          note: "Hold down control or command to select multiple",
          options: [Foo: "foo", Bar: "bar"],
          multiple: true
        }
      }
    ]
  end
end
