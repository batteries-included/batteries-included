defmodule ControlServerWeb.Live.SystemProjectShow do
  use ControlServerWeb, :live_view

  import ControlServerWeb.LeftMenuLayout

  alias ControlServer.Projects

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:system_project, Projects.get_system_project!(id))}
  end

  defp page_title(_), do: "Project"

  @impl true
  def render(assigns) do
    ~H"""
    <.layout group={:projects} active={:projects}>
      <:title>
        <.title><%= @page_title %></.title>
      </:title>
    </.layout>
    """
  end
end
