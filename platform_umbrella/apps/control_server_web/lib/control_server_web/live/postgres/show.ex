defmodule ControlServerWeb.Live.PostgresShow do
  use ControlServerWeb, :live_view

  import CommonUI.Stats
  import ControlServerWeb.LeftMenuLayout
  import ControlServerWeb.PodsDisplay
  import ControlServerWeb.ServicesDisplay

  alias ControlServer.Postgres
  alias KubeExt.KubeState
  alias KubeExt.OwnerLabel
  alias KubeExt.OwnerReference
  alias EventCenter.KubeState, as: KubeEventCenter

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    :ok = KubeEventCenter.subscribe(:pod)
    :ok = KubeEventCenter.subscribe(:postgresql)
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
     |> assign_k8_stateful_set()
     |> assign_k8_services()
     |> assign_k8_pods()}
  end

  @impl Phoenix.LiveView
  def handle_info(_unused, socket) do
    {:noreply,
     socket
     |> assign_k8_cluster()
     |> assign_k8_stateful_set()
     |> assign_k8_services()
     |> assign_k8_pods()}
  end

  defp assign_k8_cluster(%{assigns: %{cluster: cluster}} = socket) do
    assign(socket, :k8_cluster, k8_cluster(cluster.id))
  end

  defp assign_k8_stateful_set(%{assigns: assigns} = socket) do
    possible_owner_uids = [uid(assigns.k8_cluster)]
    possible_owner_ids = [assigns.cluster.id]
    sets = all_matching(:stateful_set, possible_owner_ids, possible_owner_uids)
    assign(socket, :k8_stateful_sets, sets)
  end

  defp assign_k8_services(%{assigns: assigns} = socket) do
    possible_owner_uids = [uid(assigns.k8_cluster)] ++ uids(assigns.k8_stateful_sets)
    possible_owner_ids = [assigns.cluster.id]
    services = all_matching(:service, possible_owner_ids, possible_owner_uids)
    assign(socket, :k8_services, services)
  end

  defp assign_k8_pods(%{assigns: assigns} = socket) do
    possible_owner_uids =
      [uid(assigns.k8_cluster)] ++ uids(assigns.k8_stateful_sets) ++ uids(assigns.k8_services)

    possible_owner_ids = [assigns.cluster.id]
    pods = all_matching(:pod, possible_owner_ids, possible_owner_uids)
    assign(socket, :k8_pods, pods)
  end

  defp all_matching(resource_type, owner_ids, owner_uids) do
    possible_uid_mapset = MapSet.new(owner_uids)
    possible_id_mapset = MapSet.new(owner_ids)

    resource_type
    |> KubeState.get_all()
    |> Enum.filter(fn res ->
      # Keep any resource that has a battery/owner label
      # or any resource that has a metadata -> ownerReference with a uid in owner_uids
      is_owned_by_label(res, possible_id_mapset) || is_owned_by_ref(res, possible_uid_mapset)
    end)
  end

  defp is_owned_by_ref(resource, possible_uid_mapset) do
    resource
    |> OwnerReference.get_all_owners()
    |> Enum.any?(&MapSet.member?(possible_uid_mapset, &1))
  end

  defp is_owned_by_label(resource, possible_id_mapset) do
    case OwnerLabel.get_owner(resource) do
      nil ->
        false

      owner_id ->
        MapSet.member?(possible_id_mapset, owner_id)
    end
  end

  defp uids(resources) do
    Enum.map(resources, &uid/1)
  end

  defp uid(res) do
    get_in(res, [Access.key("metadata", %{}), Access.key("uid", nil)])
  end

  defp k8_cluster(id) do
    :postgresql
    |> KubeState.get_all()
    |> Enum.find(nil, fn pg -> id == OwnerLabel.get_owner(pg) end)
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = Postgres.delete_cluster(socket.assigns.cluster)

    {:noreply, push_redirect(socket, to: ~p"/postgres/clusters")}
  end

  defp page_title(:show), do: "Show Postgres"

  defp edit_url(cluster),
    do: ~p"/postgres/clusters/#{cluster}/edit"

  defp k8_cluster_status(nil) do
    "Not Running"
  end

  defp k8_cluster_status(k8_cluster) do
    k8_cluster |> Map.get("status", %{}) |> Map.get("PostgresClusterStatus", "Not Running")
  end

  defp secret_name(cluster_name, username) do
    "#{username}.#{cluster_name}.credentials.postgresql.acid.zalan.do"
  end

  defp users_display(assigns) do
    ~H"""
    <.table id="users-display-table" rows={@cluster.users || []}>
      <:col :let={user} label="User Name"><%= user.username %></:col>
      <:col :let={user} label="Roles"><%= Enum.join(user.roles, ", ") %></:col>
      <:col :let={user} label="Secret"><%= secret_name(@cluster.name, user.username) %></:col>
    </.table>
    """
  end

  defp databases_display(assigns) do
    ~H"""
    <.table id="databases-display-table" rows={@cluster.databases || []}>
      <:col :let={db} label="Name"><%= db.name %></:col>
      <:col :let={db} label="Owner"><%= db.owner %></:col>
    </.table>
    """
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.layout group={:data} active={:postgres_operator}>
      <:title>
        <.title><%= @page_title %></.title>
      </:title>
      <.stats>
        <.stat>
          <.stat_title>Name</.stat_title>
          <.stat_value><%= @cluster.name %></.stat_value>
        </.stat>
        <.stat>
          <.stat_title>Instances</.stat_title>
          <.stat_description>The number of replics to run</.stat_description>
          <.stat_value><%= @cluster.num_instances %></.stat_value>
        </.stat>
        <.stat>
          <.stat_title>PG Version</.stat_title>
          <.stat_description>Major Version of Postgres</.stat_description>
          <.stat_value><%= @cluster.postgres_version %></.stat_value>
        </.stat>
        <.stat>
          <.stat_title>Cluster Status</.stat_title>
          <.stat_value><%= k8_cluster_status(@k8_cluster) %></.stat_value>
        </.stat>
      </.stats>

      <.section_title>Users</.section_title>
      <.users_display cluster={@cluster} />

      <.section_title>Databases</.section_title>
      <.databases_display cluster={@cluster} />

      <.section_title>Pods</.section_title>
      <.pods_display pods={@k8_pods} />

      <.section_title>Services</.section_title>
      <.services_display services={@k8_services} />

      <.h2>Actions</.h2>
      <.body_section>
        <.link navigate={edit_url(@cluster)}>
          <.button>
            Edit Cluster
          </.button>
        </.link>

        <.button phx-click="delete" data-confirm="Are you sure?">
          Delete Cluster
        </.button>
      </.body_section>
    </.layout>
    """
  end
end
