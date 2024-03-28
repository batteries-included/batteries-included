defmodule Storybook.Components.Input.Switch do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1

  def variations do
    [
      %Variation{
        id: :switch,
        attributes: %{
          type: "switch",
          name: "foo",
          value: "bar",
          label: "Label",
          checked: false
        }
      },
      %Variation{
        id: :with_errors,
        attributes: %{
          type: "switch",
          name: "foo",
          value: "bar",
          label: "Label",
          checked: false,
          errors: ["Oh no"],
          force_feedback: true
        }
      }
    ]
  end
end
