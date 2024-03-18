defmodule ControlServerWeb.Projects.ShowLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Projects

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Project Details")
     |> assign(:project, Projects.get_project!(id))}
  end

  def handle_event("delete", _params, socket) do
    {:ok, _} = Projects.delete_project(socket.assigns.project)
    {:noreply, push_navigate(socket, to: ~p"/projects")}
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/projects"}>
      <:menu>
        <.flex class="items-center">
          <.button variant="icon" icon={:trash} phx-click="delete" data-confirm="Are you sure?" />

          <.button variant="dark" icon={:clock} link={~p"/projects/#{@project.id}/timeline"}>
            Project Timeline
          </.button>
        </.flex>
      </:menu>
    </.page_header>
    """
  end
end
