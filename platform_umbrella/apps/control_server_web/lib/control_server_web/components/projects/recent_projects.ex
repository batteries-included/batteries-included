defmodule ControlServerWeb.RecentProjectsPanel do
  @moduledoc false
  use ControlServerWeb, :live_component

  import KubeServices.SystemState.SummaryRecent

  alias CommonCore.Projects.Project

  def mount(socket) do
    {:ok, assign(socket, projects: projects())}
  end

  def render(assigns) do
    ~H"""
    <div class="lg:col-span-7">
      <.panel title="Projects" class="h-full">
        <:menu>
          <.button variant="minimal" link={~p"/projects"}>View All</.button>
        </:menu>

        <.table
          :if={@projects != []}
          rows={@projects}
          row_click={&JS.navigate(~p"/projects/#{&1.id}")}
        >
          <:col :let={project} label="Project Name"><%= project.name %></:col>
          <:col :let={project} label="Project Type"><%= Project.type_name(project.type) %></:col>
        </.table>

        <div
          :if={@projects == []}
          class="flex flex-col items-center justify-center h-full text-gray-light italic"
        >
          <span>You don't have any projects.</span>
        </div>
      </.panel>
    </div>
    """
  end
end
