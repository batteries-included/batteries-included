defmodule Storybook.Components.DataList do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.DataList.data_list/1

  def variations,
    do: [
      %Variation{
        id: :default,
        slots: [
          ~s|<:item title="First">Main Text</:item>|,
          ~s|<:item title="Field Name">More Text</:item>|,
          ~s|<:item title="Views">200</:item>|
        ]
      }
    ]
end
