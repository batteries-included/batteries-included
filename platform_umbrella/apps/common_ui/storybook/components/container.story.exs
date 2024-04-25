defmodule Storybook.Components.Container do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Container.grid/1
  def container, do: {:div, class: "w-full"}

  def variations do
    [
      %Variation{
        id: :grid,
        attributes: %{
          class: "text-center"
        },
        slots: [
          "<div>A</div>",
          "<div>B</div>",
          "<div>C</div>",
          "<div>D</div>",
          "<div>E</div>",
          "<div>F</div>"
        ]
      },
      %Variation{
        id: :custom_grid,
        attributes: %{
          class: "text-center",
          columns: %{md: 1, lg: 2},
          gaps: %{md: 0, lg: 2}
        },
        slots: [
          "<div>A</div>",
          "<div>B</div>",
          "<div>C</div>",
          "<div>D</div>",
          "<div>E</div>",
          "<div>F</div>"
        ]
      }
    ]
  end
end
