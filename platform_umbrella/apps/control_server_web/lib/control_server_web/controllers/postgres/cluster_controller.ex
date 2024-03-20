defmodule ControlServerWeb.ClusterController do
  use ControlServerWeb, :controller

  alias CommonCore.Postgres.Cluster
  alias ControlServer.Postgres

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    clusters = Postgres.list_clusters()
    render(conn, :index, clusters: clusters)
  end

  def create(conn, %{"cluster" => cluster_params}) do
    with {:ok, %Cluster{} = cluster} <- Postgres.create_cluster(cluster_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/postgres/clusters/#{cluster}")
      |> render(:show, cluster: cluster)
    end
  end

  def show(conn, %{"id" => id}) do
    cluster = Postgres.get_cluster!(id)
    render(conn, :show, cluster: cluster)
  end

  def update(conn, %{"id" => id, "cluster" => cluster_params}) do
    cluster = Postgres.get_cluster!(id)

    with {:ok, %Cluster{} = cluster} <- Postgres.update_cluster(cluster, cluster_params) do
      render(conn, :show, cluster: cluster)
    end
  end

  def delete(conn, %{"id" => id}) do
    cluster = Postgres.get_cluster!(id)

    with {:ok, %Cluster{}} <- Postgres.delete_cluster(cluster) do
      send_resp(conn, :no_content, "")
    end
  end
end
