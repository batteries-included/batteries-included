defmodule Storybook.Components.DataList do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.DataList.data_list/1
  def container, do: {:div, class: "w-full"}

  def variations do
    [
      %Variation{
        id: :default,
        slots: [
          ~s|<:item title="First">Main Text</:item>|,
          ~s|<:item title="Field Name">More Text</:item>|,
          ~s|<:item title="Views" help="The total views bots have driven to twitter">200B</:item>|
        ]
      },
      %Variation{
        id: :horizontal_plain,
        attributes: %{
          variant: "horizontal-plain",
          data: [
            {"First", "Main Text"},
            {"Field Name", "More Text"},
            {"Views", 200}
          ]
        }
      },
      %Variation{
        id: :horizontal_bolded,
        attributes: %{
          variant: "horizontal-bolded",
          data: [
            {"First:", "Main Text"},
            {"Field Name:", "More Text"},
            {"Views:", 200}
          ]
        }
      }
    ]
  end
end
