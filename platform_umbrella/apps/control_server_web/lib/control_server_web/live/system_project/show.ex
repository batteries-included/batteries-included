defmodule ControlServerWeb.Live.SystemProjectShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

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

    """
  end
end
