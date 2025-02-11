defmodule ControlServerWeb.Live.PostgresShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.Audit.EditVersionsTable
  import ControlServerWeb.PgUserTable
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ResourceComponents
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
     |> assign_grafana_url()
     |> maybe_assign_edit_versions()
     |> maybe_assign_events()}
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

  defp assign_grafana_url(%{assigns: %{cluster: cluster}} = socket) do
    assign(socket, :grafana_dashboard_url, grafana_url(cluster))
  end

  defp assign_grafana_url(socket), do: socket

  defp maybe_assign_edit_versions(%{assigns: %{cluster: cluster, live_action: live_action}} = socket)
       when live_action == :edit_versions do
    assign(socket, :edit_versions, ControlServer.Audit.history(cluster))
  end

  defp maybe_assign_edit_versions(socket), do: socket

  defp maybe_assign_events(%{assigns: %{live_action: live_action, k8_cluster: k8_cluster}} = socket)
       when live_action == :events do
    assign(socket, :events, KubeState.get_events(k8_cluster))
  end

  defp maybe_assign_events(socket), do: socket

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
  defp page_title(:events), do: "Postgres Cluster: Events"
  defp page_title(:pods), do: "Postgres Cluster: Pods"
  defp page_title(:users), do: "Postgres Cluster: Users"
  defp page_title(:services), do: "Postgres Cluster: Services"
  defp page_title(:edit_versions), do: "Postgres Cluster: Edit History"

  defp edit_url(cluster), do: ~p"/postgres/#{cluster}/edit"

  defp show_url(cluster), do: ~p"/postgres/#{cluster}/show"
  defp users_url(cluster), do: ~p"/postgres/#{cluster}/users"
  defp services_url(cluster), do: ~p"/postgres/#{cluster}/services"
  defp edit_versions_url(cluster), do: ~p"/postgres/#{cluster}/edit_versions"
  defp events_url(cluster), do: ~p"/postgres/#{cluster}/events"
  defp pods_url(cluster), do: ~p"/postgres/#{cluster}/pods"

  defp info_panel(assigns) do
    ~H"""
    <.panel title="Details" class="lg:col-span-3">
      <.data_list>
        <:item title="Running Status">
          {phase(@k8_cluster)}
        </:item>
        <:item title="Instances">
          {@cluster.num_instances}
        </:item>
        <:item
          title="Type"
          help="Internal clusters are created by batteries, while standard clusters are managed by users"
        >
          {String.capitalize(Atom.to_string(@cluster.type))}
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

  defp links_panel(assigns) do
    ~H"""
    <.panel variant="gray">
      <.tab_bar variant="navigation">
        <:tab selected={@live_action == :show} patch={show_url(@cluster)}>Overview</:tab>
        <:tab selected={@live_action == :users} patch={users_url(@cluster)}>Users</:tab>
        <:tab selected={@live_action == :pods} patch={pods_url(@cluster)}>Pods</:tab>
        <:tab selected={@live_action == :services} patch={services_url(@cluster)}>Services</:tab>
        <:tab selected={@live_action == :events} patch={events_url(@cluster)}>Events</:tab>
        <:tab
          :if={@timeline_installed}
          selected={@live_action == :edit_versions}
          patch={edit_versions_url(@cluster)}
        >
          Edit Versions
        </:tab>
      </.tab_bar>
      <.a :if={@grafana_dashboard_url != nil} variant="bordered" href={@grafana_dashboard_url}>
        Grafana Dashboard
      </.a>
    </.panel>
    """
  end

  defp pg_page_header(assigns) do
    ~H"""
    <.page_header title={@title} back_link={@back_link}>
      <:menu>
        <.badge :if={@cluster.project_id}>
          <:item label="Project" navigate={~p"/projects/#{@cluster.project_id}/show"}>
            {@cluster.project.name}
          </:item>
        </.badge>
      </:menu>

      <.flex>
        <.tooltip target_id="edit-tooltip">Edit Cluster</.tooltip>
        <.tooltip target_id="delete-tooltip">Delete Cluster</.tooltip>
        <.flex gaps="0">
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
    """
  end

  defp main_page(assigns) do
    ~H"""
    <.pg_page_header
      cluster={@cluster}
      title={"Postgres Cluster: #{@cluster.name}"}
      back_link={~p"/postgres"}
    />
    <.grid columns={%{sm: 1, lg: 4}}>
      <.info_panel cluster={@cluster} k8_cluster={@k8_cluster} />
      <.links_panel
        cluster={@cluster}
        grafana_dashboard_url={@grafana_dashboard_url}
        timeline_installed={@timeline_installed}
        live_action={@live_action}
      />
    </.grid>
    """
  end

  defp users_page(assigns) do
    ~H"""
    <.pg_page_header
      cluster={@cluster}
      grafana_dashboard_url={@grafana_dashboard_url}
      title={"Postgres Users: #{@cluster.name}"}
      back_link={show_url(@cluster)}
    />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-3">
      <.panel title="Sync Status" class="lg:col-span-3 lg:row-span-2">
        <.sync_status_table status={get_in(@k8_cluster, ~w(status managedRolesStatus))} />
      </.panel>
      <.links_panel
        cluster={@cluster}
        grafana_dashboard_url={@grafana_dashboard_url}
        timeline_installed={@timeline_installed}
        live_action={@live_action}
      />
      <.panel title="Users" variant="gray" class="lg:col-span-4">
        <.pg_users_table users={@cluster.users} cluster={@cluster} />
      </.panel>
    </.grid>
    """
  end

  defp services_page(assigns) do
    ~H"""
    <.pg_page_header
      cluster={@cluster}
      grafana_dashboard_url={@grafana_dashboard_url}
      title={"Postgres Services: #{@cluster.name}"}
      back_link={show_url(@cluster)}
    />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.panel title="Services" class="lg:col-span-3 lg:row-span-2">
        <.services_table services={@k8_services} />
      </.panel>
      <.links_panel
        cluster={@cluster}
        grafana_dashboard_url={@grafana_dashboard_url}
        timeline_installed={@timeline_installed}
        live_action={@live_action}
      />
    </.grid>
    """
  end

  defp edit_versions_page(assigns) do
    ~H"""
    <.pg_page_header
      cluster={@cluster}
      grafana_dashboard_url={@grafana_dashboard_url}
      title={"Edit History: #{@cluster.name}"}
      back_link={show_url(@cluster)}
    />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.panel title="Edit History" class="lg:col-span-3 lg:row-span-2">
        <.edit_versions_table rows={@edit_versions} abridged />
      </.panel>
      <.links_panel
        cluster={@cluster}
        grafana_dashboard_url={@grafana_dashboard_url}
        timeline_installed={@timeline_installed}
        live_action={@live_action}
      />
    </.grid>
    """
  end

  defp events_page(assigns) do
    ~H"""
    <.pg_page_header
      cluster={@cluster}
      grafana_dashboard_url={@grafana_dashboard_url}
      title={"Edit History: #{@cluster.name}"}
      back_link={show_url(@cluster)}
    />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-3">
      <.events_panel class="lg:col-span-3  lg:row-span-2" events={@events} />
      <.links_panel
        cluster={@cluster}
        grafana_dashboard_url={@grafana_dashboard_url}
        timeline_installed={@timeline_installed}
        live_action={@live_action}
      />
    </.grid>
    """
  end

  defp pods_page(assigns) do
    ~H"""
    <.pg_page_header
      cluster={@cluster}
      grafana_dashboard_url={@grafana_dashboard_url}
      title={"Pods: #{@cluster.name}"}
      back_link={show_url(@cluster)}
    />

    <.grid columns={%{sm: 1, lg: 4}} class="lg:template-rows-2">
      <.panel title="Pods" class="lg:col-span-3 lg:row-span-2">
        <.pods_table pods={@k8_pods} />
      </.panel>
      <.links_panel
        cluster={@cluster}
        grafana_dashboard_url={@grafana_dashboard_url}
        timeline_installed={@timeline_installed}
        live_action={@live_action}
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
          cluster={@cluster}
          k8_cluster={@k8_cluster}
          grafana_dashboard_url={@grafana_dashboard_url}
          timeline_installed={@timeline_installed}
        />
      <% :events -> %>
        <.events_page
          live_action={@live_action}
          cluster={@cluster}
          k8_cluster={@k8_cluster}
          grafana_dashboard_url={@grafana_dashboard_url}
          timeline_installed={@timeline_installed}
          events={@events}
        />
      <% :pods -> %>
        <.pods_page
          live_action={@live_action}
          cluster={@cluster}
          k8_cluster={@k8_cluster}
          grafana_dashboard_url={@grafana_dashboard_url}
          timeline_installed={@timeline_installed}
          k8_pods={@k8_pods}
        />
      <% :users -> %>
        <.users_page
          live_action={@live_action}
          cluster={@cluster}
          k8_cluster={@k8_cluster}
          grafana_dashboard_url={@grafana_dashboard_url}
          timeline_installed={@timeline_installed}
        />
      <% :services -> %>
        <.services_page
          live_action={@live_action}
          cluster={@cluster}
          k8_cluster={@k8_cluster}
          grafana_dashboard_url={@grafana_dashboard_url}
          timeline_installed={@timeline_installed}
          k8_services={@k8_services}
        />
      <% :edit_versions -> %>
        <.edit_versions_page
          live_action={@live_action}
          cluster={@cluster}
          k8_cluster={@k8_cluster}
          grafana_dashboard_url={@grafana_dashboard_url}
          timeline_installed={@timeline_installed}
          edit_versions={@edit_versions}
        />
    <% end %>
    """
  end
end
