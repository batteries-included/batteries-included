defmodule ControlServerWeb.Live.PostgresShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.Audit.EditVersionsTable
  import ControlServerWeb.PgUserTable
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ServicesTable

  alias CommonCore.Util.Memory
  alias ControlServer.Postgres
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries
  alias KubeServices.SystemState.SummaryURLs

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :ok = KubeEventCenter.subscribe(:pod)
      :ok = KubeEventCenter.subscribe(:cloudnative_pg_cluster)
    end

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign_cluster(id)
     |> assign_page_title()
     |> assign_current_page()
     |> assign_k8_cluster()
     |> assign_k8_services()
     |> assign_k8_pods()
     |> assign_timeline_installed()
     |> maybe_assign_grafana_url()
     |> maybe_assign_edit_versions()}
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply, socket |> assign_k8_cluster() |> assign_k8_services() |> assign_k8_pods()}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = Postgres.delete_cluster(socket.assigns.cluster)

    {:noreply, push_navigate(socket, to: ~p"/postgres")}
  end

  defp assign_timeline_installed(socket) do
    assign(socket, :timeline_installed, SummaryBatteries.battery_installed(:timeline))
  end

  defp assign_cluster(socket, id) do
    cluster = Postgres.get_cluster!(id, preload: [:project])
    assign(socket, cluster: cluster, id: id)
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, page_title(socket.assigns.live_action))
  end

  defp assign_current_page(socket) do
    assign(socket, :current_page, :data)
  end

  defp assign_k8_cluster(%{assigns: %{cluster: cluster}} = socket) do
    cluster = k8_cluster(cluster.id)
    assign(socket, :k8_cluster, cluster)
  end

  defp assign_k8_services(%{assigns: %{cluster: cluster}} = socket) do
    services = k8_services(cluster.id)
    assign(socket, :k8_services, services)
  end

  defp assign_k8_pods(%{assigns: %{cluster: cluster}} = socket) do
    pods = k8_pods(cluster.id)
    assign(socket, :k8_pods, pods)
  end

  defp maybe_assign_edit_versions(%{assigns: %{cluster: cluster, live_action: live_action}} = socket)
       when live_action == :edit_versions do
    assign(socket, :edit_versions, ControlServer.Audit.history(cluster))
  end

  defp maybe_assign_edit_versions(socket), do: socket

  defp maybe_assign_grafana_url(%{assigns: %{cluster: cluster, live_action: :show}} = socket) do
    assign(socket, :grafana_dashboard_url, grafana_url(cluster))
  end

  defp maybe_assign_grafana_url(socket), do: socket

  defp grafana_url(nil), do: nil

  defp grafana_url(cluster) do
    if SummaryBatteries.battery_installed(:grafana) do
      SummaryURLs.pg_dashboard_url(cluster)
    end
  end

  defp k8_cluster(id) do
    :cloudnative_pg_cluster
    |> KubeState.get_all()
    |> Enum.find(nil, fn pg -> id == labeled_owner(pg) end)
  end

  defp k8_services(id) do
    :service
    |> KubeState.get_all()
    |> Enum.filter(fn pg -> id == labeled_owner(pg) end)
  end

  defp k8_pods(id) do
    :pod
    |> KubeState.get_all()
    |> Enum.filter(fn pg -> id == labeled_owner(pg) end)
  end

  defp all_roles(status) do
    status
    |> Map.get("byStatus", %{})
    |> Enum.flat_map(fn {_, roles} -> roles end)
    |> Enum.uniq()
  end

  defp get_role_status(status, role) do
    status
    |> Map.get("byStatus", %{})
    |> Enum.filter(fn {_, roles_in_status} -> role in roles_in_status end)
    |> Enum.map(fn {status, _} -> status end)
    |> List.first("Unkown")
  end

  defp password_resource_version(status, role) do
    status
    |> Map.get("passwordStatus")
    |> Kernel.||(%{})
    |> Map.get(role, %{})
    |> Map.get("resourceVersion", "-")
  end

  defp page_title(:show), do: "Postgres Cluster"
  defp page_title(:users), do: "Postgres Cluster: Users"
  defp page_title(:services), do: "Postgres Cluster: Services"
  defp page_title(:edit_versions), do: "Postgres Cluster: Edit History"

  defp edit_url(cluster), do: ~p"/postgres/#{cluster}/edit"

  defp show_url(cluster), do: ~p"/postgres/#{cluster}/show"
  defp users_url(cluster), do: ~p"/postgres/#{cluster}/users"
  defp services_url(cluster), do: ~p"/postgres/#{cluster}/services"
  defp edit_versions_url(cluster), do: ~p"/postgres/#{cluster}/edit_versions"

  defp links_panel(assigns) do
    ~H"""
    <.flex column class="justify-start">
      <.a variant="bordered" navigate={users_url(@cluster)}>Users</.a>
      <.a variant="bordered" navigate={services_url(@cluster)}>Services</.a>
      <.a :if={@grafana_dashboard_url} variant="bordered" href={@grafana_dashboard_url}>
        Grafana Dashboard
      </.a>
    </.flex>
    """
  end

  defp info_panel(assigns) do
    ~H"""
    <.panel title="Details" variant="gray">
      <.data_list>
        <:item title="Running Status">
          {phase(@k8_cluster)}
        </:item>
        <:item title="Instances">
          {@cluster.num_instances}
        </:item>
        <:item title="Storage Size">
          {Memory.humanize(@cluster.storage_size)}
        </:item>
        <:item :if={@cluster.memory_limits} title="Memory limits">
          {Memory.humanize(@cluster.memory_limits)}
        </:item>
        <:item title="Started">
          <.relative_display time={creation_timestamp(@k8_cluster)} />
        </:item>
      </.data_list>
    </.panel>
    """
  end

  defp sync_status_table(assigns) do
    ~H"""
    <.table id="postgres-sync-status-table" rows={all_roles(@status)}>
      <:col :let={user} label="Name">{user}</:col>
      <:col :let={user} label="Status">{get_role_status(@status, user)}</:col>
      <:col :let={user} label="Password Resource">
        {password_resource_version(@status, user)}
      </:col>
    </.table>
    """
  end

  defp main_page(assigns) do
    ~H"""
    <.page_header title={"Postgres Cluster: #{@cluster.name}"} back_link={~p"/postgres"}>
      <:menu>
        <.badge :if={@cluster.project_id}>
          <:item label="Project" navigate={~p"/projects/#{@cluster.project_id}"}>
            {@cluster.project.name}
          </:item>
        </.badge>
      </:menu>

      <.flex>
        <.tooltip :if={@timeline_installed} target_id="history-tooltip">Edit History</.tooltip>
        <.tooltip target_id="edit-tooltip">Edit Cluster</.tooltip>
        <.tooltip target_id="delete-tooltip">Delete Cluster</.tooltip>
        <.flex gaps="0">
          <.button
            :if={@timeline_installed}
            id="history-tooltip"
            variant="icon"
            icon={:clock}
            link={edit_versions_url(@cluster)}
          />
          <.button id="edit-tooltip" variant="icon" icon={:pencil} link={edit_url(@cluster)} />
          <.button
            id="delete-tooltip"
            variant="icon"
            icon={:trash}
            phx-click="delete"
            data-confirm="Are you sure?"
          />
        </.flex>
      </.flex>
    </.page_header>

    <.grid columns={%{sm: 1, lg: 2}}>
      <.info_panel cluster={@cluster} k8_cluster={@k8_cluster} />
      <.links_panel cluster={@cluster} grafana_dashboard_url={@grafana_dashboard_url} />
      <.panel title="Pods" class="col-span-2">
        <.pods_table pods={@k8_pods} />
      </.panel>
    </.grid>
    """
  end

  defp users_page(assigns) do
    ~H"""
    <.page_header title="Users" back_link={show_url(@cluster)} />

    <.flex column>
      <.panel title="Users">
        <.pg_users_table users={@cluster.users} cluster={@cluster} />
      </.panel>
      <.panel title="Sync Status" variant="gray">
        <.sync_status_table status={get_in(@k8_cluster, ~w(status managedRolesStatus))} />
      </.panel>
    </.flex>
    """
  end

  defp services_page(assigns) do
    ~H"""
    <.page_header title="Network Services" back_link={show_url(@cluster)} />
    <.panel title="Services">
      <.services_table services={@k8_services} />
    </.panel>
    """
  end

  defp edit_versions_page(assigns) do
    ~H"""
    <.page_header title="Edit History" back_link={show_url(@cluster)} />
    <.panel title="Edit History">
      <.edit_versions_table rows={@edit_versions} abridged />
    </.panel>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <%= case @live_action do %>
      <% :show -> %>
        <.main_page
          cluster={@cluster}
          k8_cluster={@k8_cluster}
          k8_pods={@k8_pods}
          k8_services={@k8_services}
          grafana_dashboard_url={@grafana_dashboard_url}
          timeline_installed={@timeline_installed}
        />
      <% :users -> %>
        <.users_page cluster={@cluster} k8_cluster={@k8_cluster} />
      <% :services -> %>
        <.services_page cluster={@cluster} k8_services={@k8_services} />
      <% :edit_versions -> %>
        <.edit_versions_page cluster={@cluster} edit_versions={@edit_versions} />
    <% end %>
    """
  end
end
