defmodule ControlServerWeb.Projects.ShowLive do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors, only: [labeled_owner: 1]
  import ControlServerWeb.FerretServicesTable
  import ControlServerWeb.KnativeServicesTable
  import ControlServerWeb.PodsTable
  import ControlServerWeb.PostgresClusterTable
  import ControlServerWeb.RedisTable

  alias ControlServer.Projects
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Project Details")
     |> assign_timeline_installed()
     |> assign_project(id)
     |> assign_pods()}
  end

  defp assign_timeline_installed(socket) do
    assign(socket, :timeline_installed, SummaryBatteries.battery_installed(:timeline))
  end

  defp assign_project(socket, id) do
    assign(socket, project: Projects.get_project!(id))
  end

  defp assign_pods(%{assigns: %{project: project}} = socket) do
    postgres_ids = Enum.map(project.postgres_clusters, & &1.id)
    redis_ids = Enum.map(project.redis_clusters, & &1.id)
    ferret_ids = Enum.map(project.ferret_services, & &1.id)
    knative_ids = Enum.map(project.knative_services, & &1.id)

    allowed_ids = MapSet.new(postgres_ids ++ redis_ids ++ ferret_ids ++ knative_ids)
    pods = Enum.filter(KubeState.get_all(:pod), fn pod -> MapSet.member?(allowed_ids, labeled_owner(pod)) end)

    assign(socket, pods: pods)
  end

  def handle_event("delete", _params, socket) do
    case Projects.delete_project(socket.assigns.project) do
      {:ok, _} ->
        {:noreply, push_navigate(socket, to: ~p"/projects")}

      {:error, _changeset} ->
        # TODO: Either show a more detailed error message, or maybe just
        # nullify the project_id in each resource after showing a warning
        {:noreply, put_flash(socket, :global_error, "Project still has resources")}
    end
  end

  def render(assigns) do
    ~H"""
    <.page_header title={@page_title <> ": " <> @project.name} back_link={~p"/projects"}>
      <.flex>
        <.tooltip target_id="add-tooltip">Add Resources</.tooltip>
        <.tooltip target_id="edit-tooltip">Edit Project</.tooltip>
        <.tooltip :if={@timeline_installed} target_id="history-tooltip">Project History</.tooltip>
        <.flex gaps="0">
          <.dropdown>
            <:trigger>
              <.button id="add-tooltip" variant="icon" icon={:plus} />
            </:trigger>

            <.dropdown_link navigate={~p"/postgres/new?project_id=#{@project.id}"}>
              Postgres
            </.dropdown_link>

            <.dropdown_link navigate={~p"/redis/new?project_id=#{@project.id}"}>
              Redis
            </.dropdown_link>

            <.dropdown_link navigate={~p"/ferretdb/new?project_id=#{@project.id}"}>
              FerretDB
            </.dropdown_link>

            <.dropdown_link navigate={~p"/knative/services/new?project_id=#{@project.id}"}>
              Knative Service
            </.dropdown_link>
          </.dropdown>

          <.button
            id="edit-tooltip"
            variant="icon"
            icon={:pencil}
            link={~p"/projects/#{@project.id}/edit"}
          />

          <.button
            :if={@timeline_installed}
            id="history-tooltip"
            variant="icon"
            icon={:clock}
            link={~p"/projects/#{@project.id}/timeline"}
          />
        </.flex>
      </.flex>
    </.page_header>

    <.grid columns={[sm: 1, lg: 2]}>
      <.panel :if={@project.description} title="Project Description">
        <%= @project.description %>
      </.panel>

      <.panel :if={@project.postgres_clusters != []} variant="gray" title="Postgres">
        <.postgres_clusters_table abbridged rows={@project.postgres_clusters} />
      </.panel>

      <.panel :if={@project.redis_clusters != []} variant="gray" title="Redis">
        <.redis_table abbridged rows={@project.redis_clusters} />
      </.panel>

      <.panel :if={@project.ferret_services != []} variant="gray" title="FerretDB/MongoDB">
        <.ferret_services_table abbridged rows={@project.ferret_services} />
      </.panel>

      <.panel :if={@project.knative_services != []} variant="gray" title="Knative Services">
        <.knative_services_table abbridged rows={@project.knative_services} />
      </.panel>

      <.panel title="Pods" class="col-span-2">
        <.pods_table pods={@pods} />
      </.panel>
    </.grid>
    """
  end
end
