defmodule ControlServerWeb.ServicesLive.PostgresNew do
  use ControlServerWeb, :surface_view

  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster
  alias ControlServerWeb.Layout
  alias ControlServerWeb.ServicesLive.Postgres.FormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    cluster = %Cluster{}
    changeset = Postgres.change_cluster(cluster)

    {:ok,
     socket
     |> Surface.init()
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
    new_path = Routes.services_postgres_home_path(socket, :index)
    Logger.debug("new_cluster = #{inspect(cluster)} new_path = #{new_path}")

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Layout>
      <h1>New Postgres Cluster</h1>
      <div>
        <FormComponent
          cluster={@cluster}
          id={@cluster.id || "new-cluster-form"}
          action={:new}
          save_target={self()}
        />
      </div>
    </Layout>
    """
  end
end
