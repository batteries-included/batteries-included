defmodule ControlServerWeb.Live.SystemProjectShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Projects
  alias ControlServerWeb.Live.Project.FormComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Project Details")
     |> assign(:system_project, Projects.get_system_project!(id))}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    {:ok, _} = Projects.delete_system_project(socket.assigns.system_project)
    {:noreply, push_navigate(socket, to: ~p"/system_projects")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/system_projects"}>
      <:menu>
        <.button variant="secondary" phx-click="delete" data-confirm="Are you sure?">
          Delete
        </.button>
      </:menu>
    </.page_header>

    <.live_component
      module={FormComponent}
      system_project={@system_project}
      id={@system_project.id}
      action={:edit}
      save_target={self()}
    />
    """
  end
end
