defmodule ControlServerWeb.Chart do
  @moduledoc false
  use ControlServerWeb, :html

  alias Jason

  @default_options %{
    responsive: true,
    plugins: %{
      legend: %{position: "bottom", labels: %{font: %{size: 16}}}
    }
  }

  attr :class, :string, default: ""
  attr :canvas_class, :string, default: "w-full h-full"
  attr :id, :string, required: true
  attr :type, :string, default: "pie"
  attr :data, :any, required: true
  attr :options, :any, default: @default_options

  @spec chart(any) :: Phoenix.LiveView.Rendered.t()
  def chart(assigns) do
    ~H"""
    <div
      class={build_class([@class])}
      id={@id}
      phx-hook="Chart"
      data-chart-type={@type}
      data-chart-data={Jason.encode!(@data)}
      data-chart-options={Jason.encode!(@options)}
    >
      <canvas id={"#{@id}-canvas"} class={@canvas_class} phx-update="ignore"></canvas>
    </div>
    """
  end
end
