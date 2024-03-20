defmodule ControlServerWeb.FailoverClusterController do
  use ControlServerWeb, :controller

  alias CommonCore.Redis.FailoverCluster
  alias ControlServer.Redis

  action_fallback ControlServerWeb.FallbackController

  def index(conn, _params) do
    failover_clusters = Redis.list_failover_clusters()
    render(conn, :index, failover_clusters: failover_clusters)
  end

  def create(conn, %{"failover_cluster" => failover_cluster_params}) do
    with {:ok, %FailoverCluster{} = failover_cluster} <- Redis.create_failover_cluster(failover_cluster_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/redis/clusters/#{failover_cluster}")
      |> render(:show, failover_cluster: failover_cluster)
    end
  end

  def show(conn, %{"id" => id}) do
    failover_cluster = Redis.get_failover_cluster!(id)
    render(conn, :show, failover_cluster: failover_cluster)
  end

  def update(conn, %{"id" => id, "failover_cluster" => failover_cluster_params}) do
    failover_cluster = Redis.get_failover_cluster!(id)

    with {:ok, %FailoverCluster{} = failover_cluster} <-
           Redis.update_failover_cluster(failover_cluster, failover_cluster_params) do
      render(conn, :show, failover_cluster: failover_cluster)
    end
  end

  def delete(conn, %{"id" => id}) do
    failover_cluster = Redis.get_failover_cluster!(id)

    with {:ok, %FailoverCluster{}} <- Redis.delete_failover_cluster(failover_cluster) do
      send_resp(conn, :no_content, "")
    end
  end
end
