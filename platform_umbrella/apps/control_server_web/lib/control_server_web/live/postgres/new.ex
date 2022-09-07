defmodule ControlServerWeb.Live.PostgresNew do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster
  alias ControlServer.Services.RunnableService
  alias ControlServerWeb.Live.PostgresFormComponent

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

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
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
    new_path = show_url(cluster)
    Logger.debug("new_cluster = #{inspect(cluster)} new_path = #{new_path}")
    RunnableService.activate!(:database_public)

    {:noreply, push_redirect(socket, to: new_path)}
  end

  defp show_url(cluster),
    do: Routes.postgres_show_path(ControlServerWeb.Endpoint, :show, cluster.id)

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>New Cluster</.title>
      </:title>
      <.h3>New Postgres Cluster</.h3>
      <div>
        <.live_component
          module={PostgresFormComponent}
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
