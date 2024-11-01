defmodule ControlServerWeb.ProjectsSubcomponents do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Projects.Project

  attr :title, :string, required: true
  attr :flash, :map, default: %{}
  attr :description, :string, default: nil
  attr :last_step, :boolean, default: false

  slot :inner_block

  def subform(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <div class="grid lg:grid-cols-[2fr,1fr] content-start flex-1 gap-4">
        <.panel title={@title}>
          <.fieldset flash={@flash}>
            <%= render_slot(@inner_block) %>
          </.fieldset>
        </.panel>

        <.panel :if={@description} title="Description">
          <.markdown content={@description} />
        </.panel>
      </div>

      <div class="flex items-center justify-end gap-4">
        <.button variant="secondary" icon={:play_circle} phx-click={show_modal("demo-video-modal")}>
          View Demo Video
        </.button>

        <.button
          :if={!@last_step}
          variant="primary"
          icon={:arrow_right}
          icon_position={:right}
          type="submit"
        >
          Next Step
        </.button>

        <.button :if={@last_step} variant="primary" type="submit" phx-disable-with="Creating...">
          Create Project
        </.button>
      </div>
    </div>
    """
  end

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
