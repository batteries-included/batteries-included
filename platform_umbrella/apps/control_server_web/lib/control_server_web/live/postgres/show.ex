defmodule ControlServerWeb.Live.PostgresShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors
  import CommonUI.DatetimeDisplay
  import CommonUI.Table
  import ControlServerWeb.Audit.EditVersionsTable
  import ControlServerWeb.PgUserTable
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ServicesTable

  alias CommonCore.Util.Memory
  alias ControlServer.Postgres
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState
  alias KubeServices.SystemState.SummaryBatteries
  alias KubeServices.SystemState.SummaryHosts

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = KubeEventCenter.subscribe(:pod)
    :ok = KubeEventCenter.subscribe(:cloudnative_pg_cluster)
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

    {:noreply, push_redirect(socket, to: ~p"/postgres")}
  end

  defp assign_cluster(socket, id) do
    cluster = Postgres.get_cluster!(id)
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

  defp maybe_assign_grafana_url(%{assigns: %{cluster: cluster, k8_cluster: k8_cluster, live_action: :show}} = socket) do
    assign(socket, :grafana_dashboard_url, grafana_url(cluster, k8_cluster))
  end

  defp maybe_assign_grafana_url(socket), do: socket

  defp grafana_url(cluster, k8_cluster) do
    # TODO(elliott): This should be in a SummaryUrls module
    # and not depend on the k8_cluster
    if SummaryBatteries.battery_installed(:grafana) do
      host = SummaryHosts.grafana_host()
      namespace = namespace(k8_cluster)

      "//#{host}/d/cloudnative-pg/cloudnativepg?var-namespace=#{namespace}&var-cluster=pg-#{cluster.name}"
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
      <.bordered_menu_item navigate={users_url(@cluster)} title="Users" />
      <.bordered_menu_item navigate={services_url(@cluster)} title="Services" />
      <.bordered_menu_item
        :if={@grafana_dashboard_url}
        href={@grafana_dashboard_url}
        title="Grafana Dashboard"
      />
    </.flex>
    """
  end

  defp info_panel(assigns) do
    ~H"""
    <.panel title="Details" variant="gray">
      <.data_list>
        <:item title="Running Status">
          <%= phase(@k8_cluster) %>
        </:item>
        <:item title="Instances">
          <%= @cluster.num_instances %>
        </:item>
        <:item title="Storage Size">
          <%= @cluster.storage_size |> Memory.format_bytes(true) %>
        </:item>
        <:item :if={@cluster.memory_limits} title="Memory limits">
          <%= @cluster.memory_limits |> Memory.format_bytes(true) %>
        </:item>
      </.data_list>
    </.panel>
    """
  end

  defp sync_status_table(assigns) do
    ~H"""
    <.table rows={all_roles(@status)}>
      <:col :let={user} label="Name"><%= user %></:col>
      <:col :let={user} label="Status"><%= get_role_status(@status, user) %></:col>
      <:col :let={user} label="Password Resource">
        <%= password_resource_version(@status, user) %>
      </:col>
    </.table>
    """
  end

  defp main_page(assigns) do
    ~H"""
    <.page_header
      title={"Postgres Cluster: #{@cluster.name}"}
      back_button={%{link_type: "live_redirect", to: ~p"/postgres"}}
    >
      <:menu>
        <.flex>
          <.data_horizontal_bordered>
            <:item title="Status">
              <%= phase(@k8_cluster) %>
            </:item>
            <:item title="Started">
              <.relative_display time={creation_timestamp(@k8_cluster)} />
            </:item>
          </.data_horizontal_bordered>

          <PC.button to={edit_versions_url(@cluster)} link_type="a" color="light">
            Edit History
          </PC.button>

          <.flex gaps="0">
            <PC.icon_button to={edit_url(@cluster)} link_type="live_redirect">
              <Heroicons.pencil solid />
            </PC.icon_button>

            <PC.icon_button type="button" phx-click="delete" data-confirm="Are you sure?">
              <Heroicons.trash />
            </PC.icon_button>
          </.flex>
        </.flex>
      </:menu>
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
    <.page_header title="Users" back_button={%{link_type: "live_redirect", to: show_url(@cluster)}} />

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
    <.page_header
      title="Network Services"
      back_button={%{link_type: "live_redirect", to: show_url(@cluster)}}
    />
    <.panel title="Services">
      <.services_table services={@k8_services} />
    </.panel>
    """
  end

  defp edit_versions_page(assigns) do
    ~H"""
    <.page_header
      title="Edit History"
      back_button={%{link_type: "live_redirect", to: show_url(@cluster)}}
    />
    <.panel title="Edit History">
      <.edit_versions_table edit_versions={@edit_versions} abbridged />
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
