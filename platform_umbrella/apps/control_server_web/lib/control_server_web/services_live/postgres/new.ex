defmodule ControlServerWeb.ServicesLive.PostgresNew do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster
  alias ControlServerWeb.ServicesLive.Postgres.FormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    cluster = %Cluster{}
    changeset = Postgres.change_cluster(cluster)

    {:ok,
     socket
     |> assign(:cluster, cluster)
     |> assign(:changeset, changeset)}
  end

  def update(%{cluster: cluster} = assigns, socket) do
    Logger.info("Update")
    changeset = Postgres.change_cluster(cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_info({"cluster:save", %{"cluster" => cluster}}, socket) do
    new_path = Routes.services_postgres_clusters_path(socket, :index)
    Logger.debug("new_cluster = #{inspect(cluster)} new_path = #{new_path}")

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>New Cluster</.title>
      </:title>
      <h1>New Postgres Cluster</h1>
      <div>
        <.live_component
          module={FormComponent}
          cluster={@cluster}
          id={@cluster.id || "new-cluster-form"}
          action={:new}
          save_target={self()}
        />
      </div>
    </.layout>
    """
  end
end
