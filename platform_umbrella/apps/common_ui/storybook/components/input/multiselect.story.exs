defmodule Storybook.Components.Input.Multiselect do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Input.input/1
  def container, do: {:div, class: "w-full"}

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          type: "multiselect",
          name: "foobar",
          value: ["example-2", "example-4"],
          options: [
            %{name: "Example 1", value: "example-1"},
            %{name: "Example 2", value: "example-2"},
            %{name: "Example 3", value: "example-3", disabled: true},
            %{name: "Example 4", value: "example-4"}
          ]
        }
      },
      %Variation{
        id: :with_error,
        attributes: %{
          type: "multiselect",
          name: "foobar",
          value: ["example-1"],
          options: [
            %{name: "Example 1", value: "example-1"},
            %{name: "Example 2", value: "example-2"},
            %{name: "Example 3", value: "example-3", disabled: true},
            %{name: "Example 4", value: "example-4"}
          ],
          errors: ["Something went wrong"],
          force_feedback: true
        }
      }
    ]
  end
end
