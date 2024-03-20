defmodule ControlServerWeb.Projects.IndexLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Projects.Project
  alias ControlServer.Projects

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Projects")
     |> assign(:projects, Projects.list_projects())}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    project = Projects.get_project!(id)
    {:ok, _} = Projects.delete_project(project)

    {:noreply, assign(socket, :projects, Projects.list_projects())}
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/"}>
      <.button variant="dark" icon={:plus} link={~p"/projects/new"}>New Project</.button>
    </.page_header>

    <.panel title="All Projects">
      <.table id="projects" rows={@projects} row_click={&JS.navigate(~p"/projects/#{&1}")}>
        <:col :let={project} label="Name"><%= project.name %></:col>
        <:col :let={project} label="Type"><%= Project.type_name(project.type) %></:col>

        <:action :let={project}>
          <.flex class="justify-items-center">
            <.button
              variant="minimal"
              phx-click="delete"
              phx-value-id={project.id}
              data-confirm={"Are you sure you want to delete the \"#{project.name}\" project?"}
              icon={:trash}
              id={"delete_project_" <> project.id}
            />

            <.tooltip target_id={"delete_project_" <> project.id}>
              Delete Project
            </.tooltip>
          </.flex>
        </:action>
      </.table>
    </.panel>
    """
  end
end
