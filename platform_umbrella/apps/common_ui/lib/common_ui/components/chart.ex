defmodule CommonUI.Components.Chart do
  @moduledoc false
  use CommonUI, :component

  @colors %{
    "mixed" => [
      "#63E2FB",
      "#8ABEFF",
      "#FFB7D4",
      "#DC8BD6",
      "#B7A6F9",
      "#36E0D4",
      "#86EBE2",
      "#BCF5F0"
    ],
    "mint" => [
      "#36E0D4",
      "#86EBE2",
      "#BCF5F0",
      "#DADADA",
      "#f0f0f0",
      "#63e2fb",
      "#6cd1ff",
      "#8abeff"
    ],
    "berry" => [
      "#63E2FB",
      "#8ABEFF",
      "#B7A6F9",
      "#DC8BD6",
      "#F96AA3",
      "#36E0D4",
      "#86EBE2",
      "#BCF5F0"
    ],
    "dark" => [
      "#fc408b",
      "#d9459c",
      "#b14ca5",
      "#8751a5",
      "#5d529b",
      "#354f8b",
      "#124875",
      "#003f5c"
    ]
  }

  attr :id, :string, required: true
  attr :variant, :string, default: "mixed", values: ["mixed", "mint", "berry", "dark"]
  attr :class, :any, default: nil
  attr :type, :string, default: "doughnut"
  attr :data, :map, required: true
  attr :options, :map, default: %{}
  attr :merge_options, :boolean, default: true

  def chart(assigns) do
    ~H"""
    <div
      id={@id}
      class={["relative", @class]}
      phx-hook="Chart"
      data-type={@type}
      data-encoded={Jason.encode!(@data)}
      data-options={Jason.encode!(Map.merge(default_options(@merge_options, @variant), @options))}
    >
      <canvas id={"#{@id}-canvas"} class="dark:invert dark:hue-rotate-180" />
    </div>
    """
  end

  defp default_options(false, _), do: %{}

  defp default_options(true, variant) do
    %{
      radius: "80%",
      cutout: "70%",
      borderWidth: 0,
      backgroundColor: @colors[variant],
      hoverBackgroundColor: @colors[variant],
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
