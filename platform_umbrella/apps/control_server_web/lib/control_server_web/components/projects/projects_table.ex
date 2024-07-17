defmodule ControlServerWeb.ProjectsTable do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Projects.Project

  attr :rows, :list, default: []
  attr :abridged, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"

  def projects_table(assigns) do
    ~H"""
    <.table id="project-display-table" rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={project} :if={!@abridged} label="ID"><%= project.id %></:col>
      <:col :let={project} label="Name"><%= project.name %></:col>
      <:action :let={project}>
        <.flex>
          <.button
            variant="minimal"
            link={edit_url(project)}
            icon={:pencil}
            id={"edit_project_" <> project.id}
          />

          <.tooltip target_id={"edit_project_" <> project.id}>
            Edit Project
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  def show_url(%Project{} = project), do: ~p"/projects/#{project}"
  def edit_url(%Project{} = project), do: ~p"/projects/#{project}/edit"
end
