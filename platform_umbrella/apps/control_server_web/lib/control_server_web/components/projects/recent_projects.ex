defmodule ControlServerWeb.RecentProjectsPanel do
  @moduledoc false
  use ControlServerWeb, :live_component

  import KubeServices.SystemState.SummaryRecent

  def mount(socket) do
    {:ok,
     socket
     |> assign(:class, nil)
     |> assign(:projects, projects())}
  end

  def render(assigns) do
    ~H"""
    <div class={@class}>
      <.panel title="Projects" class="h-full">
        <:menu>
          <.button variant="minimal" link={~p"/projects"}>View All</.button>
        </:menu>

        <.table
          :if={@projects != []}
          rows={@projects}
          row_click={&JS.navigate(~p"/projects/#{&1.id}")}
        >
          <:col :let={project} label="Name"><%= project.name %></:col>
          <:col :let={project} label="Description">
            <.truncate_tooltip :if={project.description} value={project.description} length={72} />
          </:col>
        </.table>

        <div
          :if={@projects == []}
          class="flex flex-col items-center justify-center h-full text-gray-light"
        >
          <span>You don't have any projects.</span>
        </div>
      </.panel>
    </div>
    """
  end
end
