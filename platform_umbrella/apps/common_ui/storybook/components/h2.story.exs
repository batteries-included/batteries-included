defmodule Storybook.Components.H2 do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Typography.h2/1

  def variations,
    do: [
      %Variation{id: :default, slots: ["H2 Header"]},
      %Variation{id: :fancy, slots: [~s|Main Text|], attributes: %{variant: "fancy"}}
    ]
end
