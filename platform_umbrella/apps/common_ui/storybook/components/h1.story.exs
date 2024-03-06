defmodule Storybook.Components.H1 do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Typography.h1/1

  def variations,
    do: [
      %Variation{id: :default, slots: ["H1 Header"]},
      %Variation{id: :with_sub, slots: [~s|Main Text|, ~s|<:sub_header>Sub Header</:sub_header>|]}
    ]
end
