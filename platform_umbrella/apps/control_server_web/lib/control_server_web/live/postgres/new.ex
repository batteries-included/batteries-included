defmodule ControlServerWeb.Live.PostgresNew do
  use ControlServerWeb, :live_view

  import ControlServerWeb.MenuLayout

  alias ControlServer.Postgres
  alias ControlServer.Postgres.Cluster
  alias ControlServer.Batteries.Installer
  alias ControlServerWeb.Live.PostgresFormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    cluster = %Cluster{}
    changeset = Postgres.change_cluster(cluster)

    {:ok,
     socket
     |> assign(:cluster, cluster)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def update(%{cluster: cluster} = assigns, socket) do
    changeset = Postgres.change_cluster(cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveView
  def handle_info({"cluster:save", %{"cluster" => cluster}}, socket) do
    new_path = ~p"/postgres/clusters/#{cluster}/show"
    Installer.install!(:database_public)

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.menu_layout>
      <:title>
        <.title>New Cluster</.title>
      </:title>
      <div>
        <.live_component
          module={PostgresFormComponent}
          cluster={@cluster}
          id={@cluster.id || "new-cluster-form"}
          action={:new}
          save_target={self()}
        />
      </div>
    </.menu_layout>
    """
  end
end
