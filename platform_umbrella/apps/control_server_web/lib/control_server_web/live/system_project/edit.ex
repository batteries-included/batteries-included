defmodule ControlServerWeb.Live.SystemProjectEdit do
  use ControlServerWeb, :live_view

  import ControlServerWeb.MenuLayout

  alias ControlServer.Projects
  alias ControlServerWeb.Live.Project.FormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :system_project, Projects.get_system_project!(id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.menu_layout>
      <:title>
        <.title>Edit Project</.title>
      </:title>
      <div>
        <.live_component
          module={FormComponent}
          system_project={@system_project}
          id={@system_project.id || "edit-project-form"}
          action={:edit}
          save_target={self()}
        />
      </div>
    </.menu_layout>
    """
  end
end
