defmodule ControlServerWeb.RecentProjectsPanel do
  @moduledoc false
  use ControlServerWeb, :live_component

  import ControlServerWeb.ProjectsSubcomponents
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

        <.projects_table :if={@projects != []} abridged rows={@projects} />

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
