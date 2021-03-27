defmodule ServerWeb.Sparkline do
  use ServerWeb, :live_view
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    jitter = Enum.random(0..2000)
    :timer.send_interval(3000 + jitter, self(), :tick)

    {:ok,
     socket
     |> assign(:data, 0..30 |> Enum.map(fn _ -> Enum.random(0..3000) end))
     |> assign(:id, socket.id)}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <canvas class="sparkline"
            phx-hook="Sparkline"
            phx-update="ignore"
            id="#canvas_<%= @id %>"
            width="300px"
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

    socket
    |> assign(:data, data)
  end
end
