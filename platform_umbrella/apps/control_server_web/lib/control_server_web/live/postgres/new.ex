defmodule ControlServerWeb.Live.PostgresNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  alias CommonCore.Postgres.Cluster
  alias ControlServer.Batteries.Installer
  alias ControlServer.Postgres
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

  @impl Phoenix.LiveView
  def handle_info({"cluster:save", %{"cluster" => cluster}}, socket) do
    new_path = ~p"/postgres/#{cluster}/show"
    Installer.install!(:postgres)

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.h1>New PostgreSQL Cluster</.h1>
      <.live_component
        module={PostgresFormComponent}
        cluster={@cluster}
        id={@cluster.id || "new-cluster-form"}
        action={:new}
        save_target={self()}
      />
    </div>
    """
  end
end
