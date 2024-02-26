defmodule ControlServerWeb.Live.SystemProjectIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Projects
  alias ControlServer.Projects.SystemProject

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :system_projects, list_system_projects())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit System project")
    |> assign(:system_project, Projects.get_system_project!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New System project")
    |> assign(:system_project, %SystemProject{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing System projects")
    |> assign(:system_project, nil)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    system_project = Projects.get_system_project!(id)
    {:ok, _} = Projects.delete_system_project(system_project)

    {:noreply, assign(socket, :system_projects, list_system_projects())}
  end

  defp list_system_projects do
    Projects.list_system_projects()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.a navigate={~p"/system_projects/new"} variant="styled">New Project</.a>

    <.table
      id="system_projects"
      rows={@system_projects}
      row_click={&JS.navigate(~p"/system_projects/#{&1}")}
    >
      <:col :let={system_project} label="Name"><%= system_project.name %></:col>
      <:col :let={system_project} label="Type"><%= system_project.type %></:col>
      <:col :let={system_project} label="Description"><%= system_project.description %></:col>
    </.table>
    """
  end
end
