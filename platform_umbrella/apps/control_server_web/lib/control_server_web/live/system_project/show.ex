defmodule ControlServerWeb.Live.SystemProjectShow do
  use ControlServerWeb, {:live_view, layout: :menu}

  import ControlServerWeb.LeftMenuPage

  alias ControlServer.Projects

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:system_project, Projects.get_system_project!(id))}
  end

  defp page_title(_), do: "Project"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.left_menu_page group={:projects} active={:projects}></.left_menu_page>
    """
  end
end
