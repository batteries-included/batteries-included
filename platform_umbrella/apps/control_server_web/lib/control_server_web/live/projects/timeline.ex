defmodule ControlServerWeb.Live.ProjectsTimeline do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.Audit.EditVersionsTable

  alias ControlServer.Audit
  alias ControlServer.Projects

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Project Timeline")
     |> assign(:project_id, id)
     |> assign(:project, Projects.get_project!(id))}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, %{assigns: %{project_id: project_id}} = socket) do
    with {:ok, {edit_versions, meta}} <- Audit.list_project_edit_versions(project_id, params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:edit_versions, edit_versions)}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/projects/#{@project.id}/show"} />
    <.panel title="All Versions">
      <.edit_versions_table rows={@edit_versions} meta={@meta} />
    </.panel>
    """
  end
end
