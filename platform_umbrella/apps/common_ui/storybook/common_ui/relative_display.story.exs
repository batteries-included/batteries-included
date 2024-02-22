defmodule Storybook.CommonUI.RelativeDisplay do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.DatetimeDisplay.relative_display/1

  def attributes, do: []
  def slots, do: []

  def variations,
    do: [
      %Variation{id: :default, slots: [], attributes: %{time: DateTime.utc_now()}},
      %Variation{id: :fixed, slots: [], attributes: %{time: ~U[2021-10-30 16:52:03.912185Z]}},
      %Variation{id: :days_ago, slots: [], attributes: %{time: Timex.shift(DateTime.utc_now(), days: -3)}}
    ]
end
