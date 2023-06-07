defmodule ControlServerWeb.Storybook.Loader do
  use PhoenixStorybook.Story, :component

  def function, do: &ControlServerWeb.Loader.loader/1
  def container, do: {:div, class: "w-36 h-auto py-12"}
  def attributes, do: []
  def slots, do: []

  def variations,
    do: [
      %Variation{
        id: :default,
        attributes: %{}
      }
    ]
end
