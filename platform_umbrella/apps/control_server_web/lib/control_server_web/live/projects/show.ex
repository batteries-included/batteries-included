defmodule ControlServerWeb.Live.ProjectsShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors, only: [labeled_owner: 1]
  import ControlServerWeb.FerretServicesTable
  import ControlServerWeb.KnativeServicesTable
  import ControlServerWeb.NotebooksTable
  import ControlServerWeb.PodsTable
  import ControlServerWeb.PostgresClusterTable
  import ControlServerWeb.RedisTable
  import ControlServerWeb.TraditionalServicesTable

  alias CommonCore.Batteries.Catalog
  alias CommonCore.Projects.Project
  alias ControlServer.Projects
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries
  alias KubeServices.SystemState.SummaryURLs

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:project_export_installed, SummaryBatteries.battery_installed(:project_export))
     |> assign(:timeline_installed, SummaryBatteries.battery_installed(:timeline))
     |> assign_project(id)
     |> assign_page_title()
     |> assign_pods()
     |> assign_grafana_dashboard()}
  end

  defp assign_project(socket, id) do
    project = Projects.get_project!(id)

    resource_count =
      Project.resource_types()
      |> Enum.map(&(project |> Map.get(&1, []) |> Enum.count()))
      |> Enum.sum()

    socket
    |> assign(:project, project)
    |> assign(:resource_count, resource_count)
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, socket.assigns.project.name)
  end

  defp assign_pods(%{assigns: %{project: project}} = socket) do
    postgres_ids = Enum.map(project.postgres_clusters, & &1.id)
    redis_ids = Enum.map(project.redis_instances, & &1.id)
    ferret_ids = Enum.map(project.ferret_services, & &1.id)
    knative_ids = Enum.map(project.knative_services, & &1.id)
    traditional_ids = Enum.map(project.traditional_services, & &1.id)

    allowed_ids = MapSet.new(postgres_ids ++ redis_ids ++ ferret_ids ++ knative_ids ++ traditional_ids)
    pods = Enum.filter(KubeState.get_all(:pod), fn pod -> MapSet.member?(allowed_ids, labeled_owner(pod)) end)

    socket
    |> assign(:pods, pods)
    |> assign(:pod_count, Enum.count(pods))
  end

  defp assign_grafana_dashboard(socket) do
    url =
      if SummaryBatteries.battery_installed(:grafana) do
        SummaryURLs.project_dashboard_url(socket.assigns.project)
      end

    assign(socket, :grafana_dashboard_url, url)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _params, socket) do
    case Projects.delete_project(socket.assigns.project) do
      {:ok, _} ->
        {:noreply, push_navigate(socket, to: ~p"/projects")}

      {:error, _} ->
        {:noreply, put_flash(socket, :global_error, "Could not delete project")}
    end
  end

  defp add_link(battery_type, url) do
    if SummaryBatteries.battery_installed(battery_type) do
      url
    else
      %{group: battery_group} = Catalog.get(battery_type)

      ~p"/batteries/#{battery_group}/new/#{battery_type}?redirect_to=#{url}"
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/projects"}>
      <.flex>
        <.tooltip target_id="add-tooltip">Add Resources</.tooltip>
        <.tooltip :if={@timeline_installed} target_id="history-tooltip">Project History</.tooltip>
        <.tooltip target_id="edit-tooltip">Edit Project</.tooltip>
        <.tooltip target_id="delete-tooltip">Delete Project</.tooltip>
        <.flex gaps="0">
          <div :if={@resource_count == 0} class="self-center mr-2">
            <.badge minimal class="bg-green-500" label="Click here to add some resources -->" />
          </div>

          <.dropdown>
            <:trigger>
              <.button id="add-tooltip" variant="icon" icon={:plus} />
            </:trigger>

            <.dropdown_link navigate={
              add_link(:cloudnative_pg, ~p"/postgres/new?project_id=#{@project.id}")
            }>
              Postgres
            </.dropdown_link>

            <.dropdown_link navigate={add_link(:redis, ~p"/redis/new?project_id=#{@project.id}")}>
              Redis
            </.dropdown_link>

            <.dropdown_link navigate={
              add_link(:ferretdb, ~p"/ferretdb/new?project_id=#{@project.id}")
            }>
              FerretDB
            </.dropdown_link>

            <.dropdown_link navigate={
              add_link(:notebooks, ~p"/notebooks/new?project_id=#{@project.id}")
            }>
              Jupyter Notebook
            </.dropdown_link>

            <.dropdown_link navigate={
              add_link(:knative, ~p"/knative/services/new?project_id=#{@project.id}")
            }>
              Knative Service
            </.dropdown_link>

            <.dropdown_link navigate={
              add_link(:traditional_services, ~p"/traditional_services/new?project_id=#{@project.id}")
            }>
              Traditional Service
            </.dropdown_link>
          </.dropdown>

          <.button
            :if={@timeline_installed}
            id="history-tooltip"
            variant="icon"
            icon={:clock}
            link={~p"/projects/#{@project.id}/timeline"}
          />

          <.button
            id="edit-tooltip"
            variant="icon"
            icon={:pencil}
            link={~p"/projects/#{@project.id}/edit"}
          />

          <.button
            :if={@project_export_installed}
            variant="icon"
            icon={:arrow_down_tray}
            id={"export_project_" <> @project.id}
            link={~p"/projects/#{@project.id}/export"}
          />

          <.tooltip :if={@project_export_installed} target_id={"export_project_" <> @project.id}>
            Export Project
          </.tooltip>

          <.button
            id="delete-tooltip"
            variant="icon"
            icon={:trash}
            phx-click="delete"
            data-confirm={"Are you sure you want to delete the \"#{@project.name}\" project? This will not delete any resources."}
          />
        </.flex>
      </.flex>
    </.page_header>

    <div class="flex flex-wrap gap-4 mb-4">
      <.badge label="Resources" value={@resource_count} />
      <.badge label="Pods" value={@pod_count} />
    </div>

    <.grid columns={[sm: 1, lg: 2]}>
      <.panel title="Project Details" variant="gray">
        <.data_list>
          <:item title="Created">
            <.relative_display time={@project.inserted_at} />
          </:item>
          <:item :if={@project.description} title="Description">
            <.markdown content={@project.description} />
          </:item>
        </.data_list>
      </.panel>

      <div :if={@grafana_dashboard_url}>
        <.a :if={@grafana_dashboard_url} variant="bordered" href={@grafana_dashboard_url}>
          Grafana Dashboard
        </.a>
      </div>

      <.panel :if={@project.postgres_clusters != []} title="Postgres">
        <:menu>
          <.button variant="minimal" link={~p"/postgres"}>View All</.button>
        </:menu>
        <.postgres_clusters_table abridged rows={@project.postgres_clusters} />
      </.panel>

      <.panel :if={@project.redis_instances != []} title="Redis">
        <:menu>
          <.button variant="minimal" link={~p"/redis"}>View All</.button>
        </:menu>
        <.redis_table abridged rows={@project.redis_instances} />
      </.panel>

      <.panel :if={@project.ferret_services != []} title="FerretDB/MongoDB">
        <:menu>
          <.button variant="minimal" link={~p"/ferretdb"}>View All</.button>
        </:menu>
        <.ferret_services_table abridged rows={@project.ferret_services} />
      </.panel>

      <.panel :if={@project.jupyter_notebooks != []} title="Jupyter Notebooks">
        <:menu>
          <.button variant="minimal" link={~p"/notebooks"}>View All</.button>
        </:menu>
        <.notebooks_table abridged rows={@project.jupyter_notebooks} />
      </.panel>

      <.panel :if={@project.knative_services != []} title="Knative Services">
        <:menu>
          <.button variant="minimal" link={~p"/knative/services"}>View All</.button>
        </:menu>
        <.knative_services_table abridged rows={@project.knative_services} />
      </.panel>

      <.panel :if={@project.traditional_services != []} title="Traditional Services">
        <:menu>
          <.button variant="minimal" link={~p"/traditional_services"}>View All</.button>
        </:menu>
        <.traditional_services_table abridged rows={@project.traditional_services} />
      </.panel>

      <.panel title="Pods" class="col-span-2">
        <.pods_table pods={@pods} />
      </.panel>
    </.grid>
    """
  end
end
