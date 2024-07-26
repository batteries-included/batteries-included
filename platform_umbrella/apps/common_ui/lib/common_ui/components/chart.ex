defmodule CommonUI.Components.Chart do
  @moduledoc false
  use CommonUI, :component

  attr :id, :string, required: true
  attr :class, :any, default: nil
  attr :type, :string, default: "doughnut"
  attr :data, :map, required: true
  attr :options, :map, default: %{}
  attr :merge_options, :boolean, default: true

  def chart(assigns) do
    ~H"""
    <div
      id={@id}
      class={["relative chart-dark-invert", @class]}
      phx-hook="Chart"
      data-type={@type}
      data-encoded={Jason.encode!(@data)}
      data-options={Jason.encode!(Map.merge(default_options(@merge_options), @options))}
    >
      <canvas id={"#{@id}-canvas"} />
    </div>
    """
  end

  defp default_options(false), do: %{}

  defp default_options(true) do
    colors = [
      "#63E2FB",
      "#8ABEFF",
      "#B7A6F9",
      "#DC8BD6",
      "#F96AA3",
      "#36E0D4",
      "#86EBE2",
      "#BCF5F0"
    ]

    %{
      radius: "80%",
      cutout: "70%",
      borderWidth: 0,
      backgroundColor: colors,
      hoverBackgroundColor: colors,
      maintainAspectRatio: false,
      animation: false,
      plugins: %{
        legend: %{
          position: "right",
          labels: %{
            padding: 20,
            boxWidth: 12,
            boxHeight: 12,
            usePointStyle: true,
            font: %{
              family: "Inter Variable",
              size: 14
            }
          }
        }
      }
    }
  end
end
