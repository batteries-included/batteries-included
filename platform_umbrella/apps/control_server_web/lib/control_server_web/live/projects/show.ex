defmodule ControlServerWeb.Projects.ShowLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Projects
  alias ControlServerWeb.Projects.FormComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Project Details")
     |> assign(:project, Projects.get_project!(id))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    {:ok, _} = Projects.delete_project(socket.assigns.project)
    {:noreply, push_navigate(socket, to: ~p"/projects")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/projects"}>
      <:menu>
        <.button variant="secondary" phx-click="delete" data-confirm="Are you sure?">
          Delete
        </.button>
      </:menu>
    </.page_header>

    <.live_component
      module={FormComponent}
      project={@project}
      id={@project.id}
      action={:edit}
      save_target={self()}
    />
    """
  end
end
