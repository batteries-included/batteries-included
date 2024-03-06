defmodule Storybook.Components.Logo do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Logo.logo/1

  def variations do
    [
      %Variation{id: :default, attributes: %{class: "size-20"}},
      %Variation{id: :full, attributes: %{variant: "full"}}
    ]
  end
end
