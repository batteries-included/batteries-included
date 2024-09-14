defmodule ControlServerWeb.ProjectsTable do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Projects.Project

  attr :rows, :list, default: []
  attr :meta, :map, default: nil
  attr :abridged, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"

  def projects_table(assigns) do
    ~H"""
    <.table
      id="projects-table"
      variant={@meta && "paginated"}
      rows={@rows}
      meta={@meta}
      path={~p"/projects"}
      row_click={&JS.navigate(show_url(&1))}
    >
      <:col :let={project} :if={!@abridged} field={:id} label="ID"><%= project.id %></:col>
      <:col :let={project} field={:name} label="Name"><%= project.name %></:col>

      <:action :let={project}>
        <.button
          variant="minimal"
          link={edit_url(project)}
          icon={:pencil}
          id={"edit_project_" <> project.id}
        />

        <.tooltip target_id={"edit_project_" <> project.id}>
          Edit Project
        </.tooltip>

        <.button
          variant="minimal"
          link={show_url(project)}
          icon={:eye}
          id={"project_show_link_" <> project.id}
          class="sm:hidden"
        />
        <.tooltip target_id={"project_show_link_" <> project.id}>
          Show Project
        </.tooltip>
      </:action>
    </.table>
    """
  end

  def show_url(%Project{} = project), do: ~p"/projects/#{project}"
  def edit_url(%Project{} = project), do: ~p"/projects/#{project}/edit"
end
