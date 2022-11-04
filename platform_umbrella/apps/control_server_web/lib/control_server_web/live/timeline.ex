defmodule ControlServerWeb.TimelineLive do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.TimelineDisplay

  alias ControlServer.Timeline
  alias EventCenter.Database, as: DatabaseEventCenter

  @impl true
  def mount(_params, _session, socket) do
    DatabaseEventCenter.subscribe(:timeline_event)
    {:ok, assign(socket, :events, events())}
  end

  @impl true
  def handle_info(_, socket) do
    {:noreply, assign(socket, :events, events())}
  end

  defp events do
    Timeline.list_timeline_events()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout group={:magic} active={:timeline}>
      <:title>
        <.title>Timeline</.title>
      </:title>
      <.feed_timeline>
        <.timeline_item
          :for={event <- @events}
          action="installed"
          timestamp={event.inserted_at}
          payload={event.payload}
        />
      </.feed_timeline>
    </.layout>
    """
  end
end
