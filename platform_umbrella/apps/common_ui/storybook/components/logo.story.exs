defmodule Storybook.Components.Logo do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Logo.logo/1

  def variations do
    [
      %Variation{id: :default, attributes: %{class: "size-20"}},
      %Variation{id: :full, attributes: %{variant: "full"}},
      %Variation{id: :sad, attributes: %{variant: "sad", class: "size-20"}},
      %Variation{id: :dead, attributes: %{variant: "dead", class: "size-20"}},
      %Variation{
        id: :custom_classes,
        attributes: %{class: "size-20", positive_class: "fill-blue-400", negative_class: "fill-blue-400"}
      }
    ]
  end
end
