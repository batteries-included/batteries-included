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
    allowed_ids =
      Project.resource_types()
      |> Enum.flat_map(fn type -> Map.get(project, type, []) end)
      |> MapSet.new(& &1.id)

    pods = Enum.filter(KubeState.get_all(:pod), fn pod -> MapSet.member?(allowed_ids, labeled_owner(pod)) end)

    socket
    |> assign(:k8_pods, pods)
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

  defp show_url(project), do: ~p"/projects/#{project}/show"

  defp pods_url(project), do: ~p"/projects/#{project}/pods"

  defp timeline_url(project), do: ~p"/projects/#{project}/timeline"

  defp postgres_clusters_url(project), do: ~p"/projects/#{project}/postgres_clusters"

  defp redis_instances_url(project), do: ~p"/projects/#{project}/redis_instances"

  defp ferret_services_url(project), do: ~p"/projects/#{project}/ferret_services"

  defp jupyter_notebooks_url(project), do: ~p"/projects/#{project}/jupyter_notebooks"

  defp knative_services_url(project), do: ~p"/projects/#{project}/knative_services"

  defp traditional_services_url(project), do: ~p"/projects/#{project}/traditional_services"

  defp model_instances_url(project), do: ~p"/projects/#{project}/model_instances"

  defp links_panel(assigns) do
    ~H"""
    <.panel variant="gray">
      <.tab_bar variant="navigation">
        <:tab selected={@live_action == :show} patch={show_url(@project)}>Overview</:tab>
        <:tab selected={@live_action == :pods} patch={pods_url(@project)}>Pods</:tab>
        <:tab :if={@timeline_installed} navigate={timeline_url(@project)}>Timeline</:tab>
        <:tab :if={@project.postgres_clusters != []} patch={postgres_clusters_url(@project)}>
          Postgres Clusters
        </:tab>
        <:tab :if={@project.redis_instances != []} patch={redis_instances_url(@project)}>Redis</:tab>
        <:tab :if={@project.ferret_services != []} patch={ferret_services_url(@project)}>
          FerretDB
        </:tab>
        <:tab :if={@project.jupyter_notebooks != []} patch={jupyter_notebooks_url(@project)}>
          Notebooks
        </:tab>
        <:tab :if={@project.knative_services != []} patch={knative_services_url(@project)}>
          Knative Services
        </:tab>
        <:tab :if={@project.traditional_services != []} patch={traditional_services_url(@project)}>
          Traditional Services
        </:tab>
        <:tab :if={@project.model_instances != []} patch={model_instances_url(@project)}>
          Model Instances
        </:tab>
      </.tab_bar>
      <.a :if={@grafana_dashboard_url != nil} variant="bordered" href={@grafana_dashboard_url}>
        Grafana Dashboard
      </.a>
    </.panel>
    """
  end

  defp header(assigns) do
    ~H"""
    <.page_header title={@title} back_link={@back_link}>
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
    """
  end

  # Add these page components right before the render function:

  def postgres_clusters_page(assigns) do
    ~H"""
    <.header
      back_link={show_url(@project)}
      title={@page_title}
      project={@project}
      resource_count={@resource_count}
      timeline_installed={@timeline_installed}
      project_export_installed={@project_export_installed}
    />

    <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
      <.panel title="Postgres Clusters" class="lg:col-span-3 lg:row-span-2">
        <.postgres_clusters_table rows={@project.postgres_clusters} />
      </.panel>

      <.links_panel
        live_action={@live_action}
        project={@project}
        timeline_installed={@timeline_installed}
        project_export_installed={@project_export_installed}
        grafana_dashboard_url={@grafana_dashboard_url}
      />
    </.grid>
    """
  end

  def redis_page(assigns) do
    ~H"""
    <.header
      back_link={show_url(@project)}
      title={@page_title}
      project={@project}
      resource_count={@resource_count}
      timeline_installed={@timeline_installed}
      project_export_installed={@project_export_installed}
    />

    <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
      <.panel title="Redis Instances" class="lg:col-span-3 lg:row-span-2">
        <.redis_table rows={@project.redis_instances} />
      </.panel>

      <.links_panel
        live_action={@live_action}
        project={@project}
        timeline_installed={@timeline_installed}
        project_export_installed={@project_export_installed}
        grafana_dashboard_url={@grafana_dashboard_url}
      />
    </.grid>
    """
  end

  def ferret_services_page(assigns) do
    ~H"""
    <.header
      back_link={show_url(@project)}
      title={@page_title}
      project={@project}
      resource_count={@resource_count}
      timeline_installed={@timeline_installed}
      project_export_installed={@project_export_installed}
    />

    <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
      <.panel title="FerretDB Services" class="lg:col-span-3 lg:row-span-2">
        <.ferret_services_table rows={@project.ferret_services} />
      </.panel>

      <.links_panel
        live_action={@live_action}
        project={@project}
        timeline_installed={@timeline_installed}
        project_export_installed={@project_export_installed}
        grafana_dashboard_url={@grafana_dashboard_url}
      />
    </.grid>
    """
  end

  def notebooks_page(assigns) do
    ~H"""
    <.header
      back_link={show_url(@project)}
      title={@page_title}
      project={@project}
      resource_count={@resource_count}
      timeline_installed={@timeline_installed}
      project_export_installed={@project_export_installed}
    />

    <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
      <.panel title="Jupyter Notebooks" class="lg:col-span-3 lg:row-span-2">
        <.notebooks_table rows={@project.jupyter_notebooks} />
      </.panel>

      <.links_panel
        live_action={@live_action}
        project={@project}
        timeline_installed={@timeline_installed}
        project_export_installed={@project_export_installed}
        grafana_dashboard_url={@grafana_dashboard_url}
      />
    </.grid>
    """
  end

  def knative_services_page(assigns) do
    ~H"""
    <.header
      back_link={show_url(@project)}
      title={@page_title}
      project={@project}
      resource_count={@resource_count}
      timeline_installed={@timeline_installed}
      project_export_installed={@project_export_installed}
    />

    <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
      <.panel title="Knative Services" class="lg:col-span-3 lg:row-span-2">
        <.knative_services_table rows={@project.knative_services} />
      </.panel>

      <.links_panel
        live_action={@live_action}
        project={@project}
        timeline_installed={@timeline_installed}
        project_export_installed={@project_export_installed}
        grafana_dashboard_url={@grafana_dashboard_url}
      />
    </.grid>
    """
  end

  def traditional_services_page(assigns) do
    ~H"""
    <.header
      back_link={show_url(@project)}
      title={@page_title}
      project={@project}
      resource_count={@resource_count}
      timeline_installed={@timeline_installed}
      project_export_installed={@project_export_installed}
    />

    <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
      <.panel title="Traditional Services" class="lg:col-span-3 lg:row-span-2">
        <.traditional_services_table rows={@project.traditional_services} />
      </.panel>

      <.links_panel
        live_action={@live_action}
        project={@project}
        timeline_installed={@timeline_installed}
        project_export_installed={@project_export_installed}
        grafana_dashboard_url={@grafana_dashboard_url}
      />
    </.grid>
    """
  end

  def pods_page(assigns) do
    ~H"""
    <.header
      back_link={show_url(@project)}
      title={@page_title}
      project={@project}
      resource_count={@resource_count}
      timeline_installed={@timeline_installed}
      project_export_installed={@project_export_installed}
    />

    <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
      <.panel title="Pods" class="lg:col-span-3 lg:row-span-2">
        <.pods_table pods={@k8_pods} />
      </.panel>

      <.links_panel
        live_action={@live_action}
        project={@project}
        timeline_installed={@timeline_installed}
        project_export_installed={@project_export_installed}
        grafana_dashboard_url={@grafana_dashboard_url}
      />
    </.grid>
    """
  end

  def main_page(assigns) do
    ~H"""
    <.header
      back_link={~p"/projects"}
      title={@page_title}
      project={@project}
      resource_count={@resource_count}
      timeline_installed={@timeline_installed}
      project_export_installed={@project_export_installed}
    />

    <div class="flex flex-wrap gap-4 mb-4">
      <.badge label="Resources" value={@resource_count} />
      <.badge label="Pods" value={@pod_count} />
    </div>

    <.grid columns={[sm: 1, lg: 4]} class="lg:template-rows-2">
      <.panel title="Project Details" class="lg:col-span-3 lg:row-span-2">
        <.data_list>
          <:item title="Created">
            <.relative_display time={@project.inserted_at} />
          </:item>
          <:item :if={@project.description} title="Description">
            <.markdown content={@project.description} />
          </:item>
        </.data_list>
      </.panel>

      <.links_panel
        live_action={@live_action}
        project={@project}
        timeline_installed={@timeline_installed}
        project_export_installed={@project_export_installed}
        grafana_dashboard_url={@grafana_dashboard_url}
      />
    </.grid>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :show -> %>
        <.main_page
          live_action={@live_action}
          page_title={@page_title}
          project={@project}
          timeline_installed={@timeline_installed}
          project_export_installed={@project_export_installed}
          grafana_dashboard_url={@grafana_dashboard_url}
          resource_count={@resource_count}
          pod_count={@pod_count}
        />
      <% :pods -> %>
        <.pods_page
          live_action={@live_action}
          page_title={@page_title}
          project={@project}
          timeline_installed={@timeline_installed}
          project_export_installed={@project_export_installed}
          grafana_dashboard_url={@grafana_dashboard_url}
          resource_count={@resource_count}
          k8_pods={@k8_pods}
        />
      <% :postgres_clusters -> %>
        <.postgres_clusters_page
          live_action={@live_action}
          page_title={@page_title}
          project={@project}
          timeline_installed={@timeline_installed}
          project_export_installed={@project_export_installed}
          grafana_dashboard_url={@grafana_dashboard_url}
          resource_count={@resource_count}
        />
      <% :redis_instances -> %>
        <.redis_page
          live_action={@live_action}
          page_title={@page_title}
          project={@project}
          timeline_installed={@timeline_installed}
          project_export_installed={@project_export_installed}
          grafana_dashboard_url={@grafana_dashboard_url}
          resource_count={@resource_count}
        />
      <% :ferret_services -> %>
        <.ferret_services_page
          live_action={@live_action}
          page_title={@page_title}
          project={@project}
          timeline_installed={@timeline_installed}
          project_export_installed={@project_export_installed}
          grafana_dashboard_url={@grafana_dashboard_url}
          resource_count={@resource_count}
        />
      <% :jupyter_notebooks -> %>
        <.notebooks_page
          live_action={@live_action}
          page_title={@page_title}
          project={@project}
          timeline_installed={@timeline_installed}
          project_export_installed={@project_export_installed}
          grafana_dashboard_url={@grafana_dashboard_url}
          resource_count={@resource_count}
        />
      <% :knative_services -> %>
        <.knative_services_page
          live_action={@live_action}
          page_title={@page_title}
          project={@project}
          timeline_installed={@timeline_installed}
          project_export_installed={@project_export_installed}
          grafana_dashboard_url={@grafana_dashboard_url}
          resource_count={@resource_count}
        />
      <% :traditional_services -> %>
        <.traditional_services_page
          live_action={@live_action}
          page_title={@page_title}
          project={@project}
          timeline_installed={@timeline_installed}
          project_export_installed={@project_export_installed}
          grafana_dashboard_url={@grafana_dashboard_url}
          resource_count={@resource_count}
        />
    <% end %>
    """
  end
end
