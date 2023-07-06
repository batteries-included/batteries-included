defmodule ControlServerWeb.Live.PostgresShow do
  use ControlServerWeb, {:live_view, layout: :fresh}

  import CommonUI.Stats
  import ControlServerWeb.PodsTable
  import ControlServerWeb.ServicesTable
  import ControlServerWeb.PgDatabaseTable
  import ControlServerWeb.PgUserTable

  alias ControlServer.Postgres
  alias KubeServices.KubeState
  alias CommonCore.Resources.OwnerLabel
  alias CommonCore.Resources.OwnerReference
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

    cluster_info =
      {K8s.Resource.name(assigns.k8_cluster), K8s.Resource.namespace(assigns.k8_cluster)}

    services = all_matching(:service, possible_owner_ids, possible_owner_uids, cluster_info)
    assign(socket, :k8_services, services)
  end

  defp assign_k8_pods(%{assigns: assigns} = socket) do
    possible_owner_uids =
      [uid(assigns.k8_cluster)] ++ uids(assigns.k8_stateful_sets) ++ uids(assigns.k8_services)

    cluster_info =
      {K8s.Resource.name(assigns.k8_cluster), K8s.Resource.namespace(assigns.k8_cluster)}

    possible_owner_ids = [assigns.cluster.id]
    pods = all_matching(:pod, possible_owner_ids, possible_owner_uids, cluster_info)
    assign(socket, :k8_pods, pods)
  end

  defp all_matching(
         resource_type,
         owner_ids,
         owner_uids,
         {cluster_name, cluster_namespace} \\ {nil, nil}
       ) do
    possible_uid_mapset = MapSet.new(owner_uids)
    possible_id_mapset = MapSet.new(owner_ids)

    resource_type
    |> KubeState.get_all()
    |> Enum.filter(fn res ->
      # Keep any resource that has a battery/owner label
      # or any resource that has a metadata -> ownerReference with a uid in owner_uids
      # or any that has a postgres cluster name matching ours
      is_owned_by_label(res, possible_id_mapset) ||
        is_owned_by_ref(res, possible_uid_mapset) ||
        is_owned_by_cluster_name(res, cluster_name, cluster_namespace)
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

  defp is_owned_by_cluster_name(resource, cluster_name, cluster_namespace) do
    K8s.Resource.label(resource, "cluster-name") == cluster_name &&
      K8s.Resource.namespace(resource) == cluster_namespace
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

    {:noreply, push_redirect(socket, to: ~p"/postgres")}
  end

  defp page_title(:show), do: "Show Postgres"

  defp edit_url(cluster),
    do: ~p"/postgres/#{cluster}/edit"

  defp k8_cluster_status(nil) do
    "Not Running"
  end

  defp k8_cluster_status(k8_cluster) do
    k8_cluster |> Map.get("status", %{}) |> Map.get("PostgresClusterStatus", "Not Running")
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.h1>
      Postgres Cluster
      <:sub_header><%= @cluster.name %></:sub_header>
    </.h1>
    <.stats>
      <.stat>
        <.stat_title>Instances</.stat_title>
        <.stat_description>The number of replics to run</.stat_description>
        <.stat_value><%= @cluster.num_instances %></.stat_value>
      </.stat>
      <.stat>
        <.stat_title>Version</.stat_title>
        <.stat_description>Major Version of Postgres</.stat_description>
        <.stat_value><%= @cluster.postgres_version %></.stat_value>
      </.stat>
      <.stat>
        <.stat_title>Cluster Status</.stat_title>
        <.stat_value><%= k8_cluster_status(@k8_cluster) %></.stat_value>
      </.stat>
    </.stats>

    <div class="grid 2xl:grid-cols-2 gap-4 sm:gap-8">
      <.card>
        <:title>Users</:title>

        <.pg_users_table users={@cluster.users || []} cluster={@cluster} />
      </.card>
      <.card>
        <:title>Databases</:title>
        <.pg_databases_table databases={@cluster.databases || []} />
      </.card>
    </div>

    <.h2>Pods</.h2>
    <.pods_table pods={@k8_pods} />

    <.h2>Services</.h2>
    <.services_table services={@k8_services} />

    <.h2 variant="fancy">Actions</.h2>
    <.card>
      <div class="grid md:grid-cols-2 gap-6">
        <.a navigate={edit_url(@cluster)} class="block">
          <.button class="w-full">
            Edit Cluster
          </.button>
        </.a>

        <.button phx-click="delete" data-confirm="Are you sure?" class="w-full">
          Delete Cluster
        </.button>
      </div>
    </.card>
    """
  end
end
