defmodule ControlServerWeb.Live.PostgresShow do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import CommonCore.Resources.FieldAccessors, only: [labeled_owner: 1, phase: 1]
  import CommonUI.DatetimeDisplay
  import CommonUI.Table
  import ControlServerWeb.PgUserTable
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ServicesTable

  alias ControlServer.Postgres
  alias EventCenter.KubeState, as: KubeEventCenter
  alias KubeServices.KubeState

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
     |> assign(:id, id)
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:cluster, Postgres.get_cluster!(id))
     |> assign_k8_cluster()
     |> assign_k8_services()
     |> assign_k8_pods()}
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
    |> Map.get(role, %{})
    |> Map.get("resourceVersion", "-")
  end

  defp page_title(:show), do: "Postgres Cluster"
  defp page_title(:users), do: "Postgres Cluster: Users"
  defp page_title(:services), do: "Postgres Cluster: Services"

  defp edit_url(cluster), do: ~p"/postgres/#{cluster}/edit"

  defp show_url(cluster), do: ~p"/postgres/#{cluster}/show"
  defp users_url(cluster), do: ~p"/postgres/#{cluster}/users"
  defp services_url(cluster), do: ~p"/postgres/#{cluster}/services"

  defp main_page(assigns) do
    ~H"""
    <.page_header
      title={"Postgres Cluster: #{@cluster.name}"}
      back_button={%{link_type: "live_redirect", to: ~p"/postgres"}}
    >
      <:right_side>
        <.flex>
          <.data_horizontal_bordered>
            <:item title="Status">
              <%= phase(@k8_cluster) %>
            </:item>
            <:item title="Instances"><%= @cluster.num_instances %></:item>
            <:item title="Started">
              <.relative_display time={get_in(@k8_cluster, ~w(metadata creationTimestamp))} />
            </:item>
          </.data_horizontal_bordered>

          <.button>Edit History</.button>

          <.flex>
            <PC.icon_button to={edit_url(@cluster)} link_type="live_redirect">
              <Heroicons.pencil solid />
            </PC.icon_button>

            <PC.icon_button type="button" phx-click="delete" data-confirm="Are you sure?">
              <Heroicons.trash />
            </PC.icon_button>
          </.flex>
        </.flex>
      </:right_side>
    </.page_header>
    <.pills_menu>
      <:item title="Database Users" patch={users_url(@cluster)}>
        <%= length(@cluster.users || []) %>
      </:item>
      <:item title="Network Services" patch={services_url(@cluster)}>
        <%= length(@k8_services || []) %>
      </:item>
    </.pills_menu>
    <.panel title="Pods">
      <.pods_table pods={@k8_pods} />
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

  defp users_page(assigns) do
    ~H"""
    <.page_header title="Users" back_button={%{link_type: "live_redirect", to: show_url(@cluster)}} />

    <.grid columns={%{sm: 1, lg: 2}}>
      <.panel title="Users">
        <.pg_users_table users={@cluster.users} cluster={@cluster} />
      </.panel>
      <.panel title="Sync Status">
        <.sync_status_table status={get_in(@k8_cluster, ~w(status managedRolesStatus))} />
      </.panel>
    </.grid>
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
        />
      <% :users -> %>
        <.users_page cluster={@cluster} k8_cluster={@k8_cluster} />
      <% :services -> %>
        <.services_page cluster={@cluster} k8_services={@k8_services} />
    <% end %>
    """
  end
end
