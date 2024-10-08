defmodule Storybook.Components.DatetimeDisplay do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.DatetimeDisplay.relative_display/1

  def variations do
    [
      %Variation{id: :default, slots: [], attributes: %{time: DateTime.utc_now()}},
      %Variation{id: :fixed, slots: [], attributes: %{time: ~U[2021-10-30 16:52:03.912185Z]}},
      %Variation{id: :days_ago, slots: [], attributes: %{time: DateTime.add(DateTime.utc_now(), -3, :day)}}
    ]
  end
end
