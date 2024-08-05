defmodule ControlServerWeb.Projects.IndexLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.ProjectsTable

  alias ControlServer.Projects

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Projects")}
  end

  def handle_params(params, _session, socket) do
    with {:ok, {projects, meta}} <- Projects.list_projects(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:projects, projects)
       |> assign(:form, to_form(meta))}
    end
  end

  def handle_event("search", params, socket) do
    params = Map.delete(params, "_target")

    {:noreply, push_patch(socket, to: ~p"/projects?#{params}")}
  end

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

      <.projects_table rows={@projects} meta={@meta} />
    </.panel>
    """
  end
end
