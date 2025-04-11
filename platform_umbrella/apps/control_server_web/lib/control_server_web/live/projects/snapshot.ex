defmodule ControlServerWeb.Live.ProjectsSnapshot do
  @moduledoc false

  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Projects
  alias ControlServer.Projects.Snapshoter

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign_project(id)
     |> assign_snapshot()
     |> assign_page_title()}
  end

  defp assign_project(socket, id) do
    project = Projects.get_project!(id)

    assign(socket, :project, project)
  end

  defp assign_snapshot(%{assigns: %{project: project}} = socket) do
    {:ok, snapshot} = Snapshoter.take_snapshot(project)
    assign(socket, :snapshot, snapshot)
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "Project Snapshot")
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header back_link={~p"/projects"} title={@page_title}>
      <.button variant="dark" phx-click="export_snapshot" icon={:arrow_up_on_square_stack}>
        Export
      </.button>
    </.page_header>
    <pre>
      <%= inspect(@snapshot, pretty: true) %>
    </pre>
    """
  end
end
