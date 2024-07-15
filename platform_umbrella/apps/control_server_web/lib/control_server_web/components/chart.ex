defmodule ControlServerWeb.Chart do
  @moduledoc false
  use ControlServerWeb, :html

  attr :id, :string, required: true
  attr :class, :any, default: nil
  attr :type, :string, default: "doughnut"
  attr :data, :map, required: true
  attr :options, :map, default: %{}

  @spec chart(any) :: Phoenix.LiveView.Rendered.t()
  def chart(assigns) do
    ~H"""
    <div
      id={@id}
      class={["relative", @class]}
      phx-hook="Chart"
      data-type={@type}
      data-encoded={Jason.encode!(@data)}
      data-options={Jason.encode!(Map.merge(@options, default_options()))}
    >
      <canvas id={"#{@id}-canvas"} />
    </div>
    """
  end

  defp default_options do
    colors = [
      "#E2C1FE",
      "#FFB7D4",
      "#C1A1E5",
      "#FF88B7",
      "#E9D4FF",
      "#FFE0EC"
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
