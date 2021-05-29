defmodule ControlServerWeb.SparklineLive do
  @moduledoc """
  Live view that will generate random data for sparklines.
  """
  use ControlServerWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    jitter = Enum.random(0..2000)
    :timer.send_interval(3000 + jitter, self(), :tick)

    {:ok,
     socket
     |> assign(:data, Enum.map(0..30, fn _ -> Enum.random(0..3000) end))
     |> assign(:id, socket.id)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <canvas class="sparkline"
            phx-hook="Sparkline"
            phx-update="ignore"
            id="#canvas_<%= @id %>"
            height="32px"
            data-data="<%= @data |> Jason.encode!() %>">
    </canvas>
    """
  end

  @impl true
  def handle_info(:tick, socket) do
    {:noreply, handle_tick(socket)}
  end

  def handle_tick(socket) do
    data = Enum.take(socket.assigns.data ++ [Enum.random(0..3000)], -30)

    assign(socket, :data, data)
  end
end
