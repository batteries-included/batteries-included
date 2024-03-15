defmodule ControlServerWeb.Projects.IndexLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Projects
  alias ControlServer.Projects.Project

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :projects, list_projects())}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit project")
    |> assign(:project, Projects.get_project!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New project")
    |> assign(:project, %Project{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing projects")
    |> assign(:project, nil)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    project = Projects.get_project!(id)
    {:ok, _} = Projects.delete_project(project)

    {:noreply, assign(socket, :projects, list_projects())}
  end

  defp list_projects do
    Projects.list_projects()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.a navigate={~p"/projects/new"} variant="styled">New Project</.a>

    <.table id="projects" rows={@projects} row_click={&JS.navigate(~p"/projects/#{&1}")}>
      <:col :let={project} label="Name"><%= project.name %></:col>
      <:col :let={project} label="Type"><%= project.type %></:col>
      <:col :let={project} label="Description"><%= project.description %></:col>
    </.table>
    """
  end
end
