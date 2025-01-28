defmodule ControlServerWeb.Live.ProjectsExport do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Projects
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Export Project")
     |> assign(:project_id, id)
     |> assign(:project, Projects.get_project!(id))
     |> assign(:project_export_installed, SummaryBatteries.battery_installed(:project_export))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/projects/#{@project.id}"} />
    <.panel :if={@project_export_installed} title="Export">
      Some Exported Project Here
    </.panel>
    <div :if={!@project_export_installed}>Project export is not enabled for this install.</div>
    """
  end
end
