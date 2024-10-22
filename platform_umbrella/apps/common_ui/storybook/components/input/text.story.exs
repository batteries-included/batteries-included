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
          value: ""
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
          rows: 3
        }
      },
      %Variation{
        id: :disabled,
        attributes: %{
          name: "foobar",
          value: "Foobar",
          disabled: true
        }
      },
      %Variation{
        id: :with_error,
        attributes: %{
          name: "foobar",
          value: "",
          errors: ["Something went wrong"],
          force_feedback: true
        }
      }
    ]
  end
end
