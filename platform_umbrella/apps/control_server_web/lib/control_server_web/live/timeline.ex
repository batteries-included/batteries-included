defmodule ControlServerWeb.Live.Timeline do
  use ControlServerWeb, {:live_view, layout: :menu}

  import ControlServerWeb.LeftMenuPage
  import ControlServerWeb.TimelineDisplay

  alias ControlServer.Timeline
  alias EventCenter.Database, as: DatabaseEventCenter

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = DatabaseEventCenter.subscribe(:timeline_event)
    {:ok, assign(socket, :events, events())}
  end

  @impl Phoenix.LiveView
  def handle_info(_, socket) do
    {:noreply, assign(socket, :events, events())}
  end

  defp events do
    Timeline.list_timeline_events()
  end

  @impl Phoenix.LiveView
  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.left_menu_page group={:magic} active={:timeline}>
      <.feed_timeline>
        <.timeline_item
          :for={{event, idx} <- Enum.with_index(@events)}
          timestamp={event.inserted_at}
          index={idx}
          payload={event.payload}
        />
      </.feed_timeline>
    </.left_menu_page>
    """
  end
end
