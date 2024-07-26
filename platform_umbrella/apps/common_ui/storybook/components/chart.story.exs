defmodule Storybook.Components.Chart do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  def function, do: &CommonUI.Components.Chart.chart/1

  def variations do
    [
      %Variation{
        id: :mixed,
        attributes: %{
          data: %{
            labels: ["Foo", "Bar", "Baz", "Qux", "Quux", "Corge", "Grault", "Garply"],
            datasets: [
              %{label: "Total", data: [1, 2, 3, 4, 5, 4, 3, 2]}
            ]
          }
        }
      },
      %Variation{
        id: :mint,
        attributes: %{
          variant: "mint",
          data: %{
            labels: ["Foo", "Bar", "Baz", "Qux", "Quux", "Corge", "Grault", "Garply"],
            datasets: [
              %{label: "Total", data: [1, 2, 3, 4, 5, 4, 3, 2]}
            ]
          }
        }
      },
      %Variation{
        id: :berry,
        attributes: %{
          variant: "berry",
          data: %{
            labels: ["Foo", "Bar", "Baz", "Qux", "Quux", "Corge", "Grault", "Garply"],
            datasets: [
              %{label: "Total", data: [1, 2, 3, 4, 5, 4, 3, 2]}
            ]
          }
        }
      },
      %Variation{
        id: :dark,
        attributes: %{
          variant: "dark",
          data: %{
            labels: ["Foo", "Bar", "Baz", "Qux", "Quux", "Corge", "Grault", "Garply"],
            datasets: [
              %{label: "Total", data: [1, 2, 3, 4, 5, 4, 3, 2]}
            ]
          }
        }
      },
      %Variation{
        id: :no_legend,
        attributes: %{
          data: %{
            datasets: [
              %{label: "Total", data: [1, 1, 1, 1, 1, 1, 1, 1]}
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
