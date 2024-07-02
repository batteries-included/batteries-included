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
              link={~p"/projects/#{project.id}"}
              icon={:eye}
              id={"show_project_" <> project.id}
            />

            <.tooltip target_id={"show_project_" <> project.id}>
              Show Project
            </.tooltip>

            <.button
              variant="minimal"
              link={~p"/projects/#{project.id}/edit"}
              icon={:pencil}
              id={"edit_project_" <> project.id}
            />

            <.tooltip target_id={"edit_project_" <> project.id}>
              Edit Project
            </.tooltip>
          </.flex>
        </:action>
      </.table>
    </.panel>
    """
  end
end
