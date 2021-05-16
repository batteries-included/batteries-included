defmodule ControlServerWeb.ClusterLive.Index do
  @moduledoc """
  The Clusters live index module.
  """
  use ControlServerWeb, :live_view

  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :clusters, list_clusters())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Cluster")
    |> assign(:cluster, Postgres.get_cluster!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Cluster")
    |> assign(:cluster, %Cluster{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Clusters")
    |> assign(:cluster, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cluster = Postgres.get_cluster!(id)
    {:ok, _} = Postgres.delete_cluster(cluster)

    {:noreply, assign(socket, :clusters, list_clusters())}
  end

  defp list_clusters do
    Postgres.list_clusters()
  end
end
