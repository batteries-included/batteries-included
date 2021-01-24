defmodule ServerWeb.KubeClusterLive.Index do
  use ServerWeb, :live_view

  alias Server.Clusters
  alias Server.Clusters.KubeCluster

  @impl true
  def mount(_params, _session, socket) do
    Clusters.subscribe()

    {:ok, assign(socket, :kube_clusters, list_kube_clusters())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Kube cluster")
    |> assign(:kube_cluster, Clusters.get_kube_cluster!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Kube cluster")
    |> assign(:kube_cluster, %KubeCluster{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Kube clusters")
    |> assign(:kube_cluster, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    kube_cluster = Clusters.get_kube_cluster!(id)
    {:ok, _} = Clusters.delete_kube_cluster(kube_cluster)

    {:noreply, assign(socket, :kube_clusters, list_kube_clusters())}
  end

  def handle_info({Clusters, _, _}, socket) do
    {:noreply, assign(socket, :kube_clusters, list_kube_clusters())}
  end

  defp list_kube_clusters do
    Clusters.list_kube_clusters()
  end
end
