defmodule ServerWeb.KubeClusterController do
  use ServerWeb, :controller

  alias Server.Clusters
  alias Server.Clusters.KubeCluster

  action_fallback ServerWeb.FallbackController

  def index(conn, _params) do
    kube_clusters = Clusters.list_kube_clusters()
    render(conn, "index.json", kube_clusters: kube_clusters)
  end

  def create(conn, %{"kube_cluster" => kube_cluster_params}) do
    with {:ok, %KubeCluster{} = kube_cluster} <-
           Clusters.create_kube_cluster(kube_cluster_params, :api) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.kube_cluster_path(conn, :show, kube_cluster))
      |> render("show.json", kube_cluster: kube_cluster)
    end
  end

  def show(conn, %{"id" => id}) do
    kube_cluster = Clusters.get_kube_cluster!(id)
    render(conn, "show.json", kube_cluster: kube_cluster)
  end

  def update(conn, %{"id" => id, "kube_cluster" => kube_cluster_params}) do
    kube_cluster = Clusters.get_kube_cluster!(id)

    with {:ok, %KubeCluster{} = kube_cluster} <-
           Clusters.update_kube_cluster(kube_cluster, kube_cluster_params, :api) do
      render(conn, "show.json", kube_cluster: kube_cluster)
    end
  end

  def delete(conn, %{"id" => id}) do
    kube_cluster = Clusters.get_kube_cluster!(id)

    with {:ok, %KubeCluster{}} <- Clusters.delete_kube_cluster(kube_cluster) do
      send_resp(conn, :no_content, "")
    end
  end
end
