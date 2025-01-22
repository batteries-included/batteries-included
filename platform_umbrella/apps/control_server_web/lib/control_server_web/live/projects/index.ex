defmodule ControlServerWeb.Live.ProjectsIndex do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.ProjectsSubcomponents

  alias ControlServer.Projects
  alias KubeServices.SystemState.SummaryBatteries

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Projects")
     |> assign(:project_export_installed, SummaryBatteries.battery_installed(:project_export))}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {projects, meta}} <- Projects.list_projects(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:projects, projects)
       |> assign(:form, to_form(meta))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("search", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/projects?#{params}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/"}>
      <.button variant="dark" icon={:plus} link={~p"/projects/new"}>New Project</.button>
    </.page_header>

    <.panel title="All Projects">
      <:menu>
        <.table_search
          meta={@meta}
          fields={[name: [op: :ilike]]}
          placeholder="Filter by name"
          on_change="search"
        />
      </:menu>

      <.projects_table rows={@projects} meta={@meta} export_enabled={@project_export_installed} />
    </.panel>
    """
  end
end
