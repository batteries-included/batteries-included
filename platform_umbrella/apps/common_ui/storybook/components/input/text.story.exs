defmodule Storybook.Components.Input.Text do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1
  def container, do: {:div, class: "w-full"}

  def variations do
    [
      %Variation{
        id: :text,
        attributes: %{
          name: "foobar",
          value: "",
          label: "Label",
          note: "This is a note"
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
        id: :with_error,
        attributes: %{
          name: "foobar",
          value: "",
          label: "Label",
          errors: ["Something went wrong"],
          force_feedback: true
        }
      }
    ]
  end
end
