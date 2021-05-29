defmodule HomeBaseWeb.BillingReportLive.ChartComponent do
  @moduledoc """
  Component for displaying the chart on the billing report show page. This is a simple chart.js thing.
  """
  use HomeBaseWeb, :live_component

  def render(assigns) do
    ~L"""
    <div class="chart-container mx-auto" style="position: relative; height:50vh; width:75vw">
      <canvas class="billing_chart"
              phx-hook="BillingChart"
              phx-update="ignore"
              id="billing_chart_<%= @id %>"
              data-data="<%= @data |> Jason.encode!() %>">
      </canvas>
    </div>
    """
  end
end
