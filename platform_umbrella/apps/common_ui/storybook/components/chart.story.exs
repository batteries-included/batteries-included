defmodule Storybook.Components.Chart do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Chart.chart/1

  def variations do
    [
      %Variation{
        id: :default,
        attributes: %{
          data: %{
            labels: ["Foo", "Bar", "Baz", "Qux"],
            datasets: [
              %{label: "Total", data: [1, 2, 3, 4]}
            ]
          }
        }
      },
      %Variation{
        id: :no_legend,
        attributes: %{
          data: %{
            datasets: [
              %{label: "Total", data: [1, 2, 3, 4, 5, 6]}
            ]
          },
          options: %{
            plugins: %{
              legend: %{
                display: false
              }
            }
          }
        }
      }
    ]
  end
end
