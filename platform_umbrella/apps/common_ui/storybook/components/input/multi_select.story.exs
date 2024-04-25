defmodule Storybook.Components.MultiSelect do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.MutliSelect.muliselect_input/1

  def variations,
    do: [
      %Variation{
        id: :default,
        attributes: %{
          options: [
            %{label: "Example 1", value: "1", selected: false},
            %{label: "Example 2", value: "2", selected: false},
            %{label: "Example 3", value: "3", selected: true},
            %{label: "Example 4", value: "4", selected: false}
          ],
          label: "Example Multi Select"
        }
      }
    ]
end
