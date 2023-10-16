defmodule ControlServerWeb.Live.PostgresNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGDatabase
  alias CommonCore.Postgres.PGUser
  alias ControlServerWeb.Live.PostgresFormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    # Pre-populate the databases and users with decent permissions
    cluster = %Cluster{
      virtual_size: "medium",
      databases: [%PGDatabase{name: "app", owner: "app"}],
      users: [%PGUser{username: "app", roles: ["login", "createdb", "createrole"]}],
      credential_copies: []
    }

    socket =
      socket
      |> assign(current_page: :datastores)
      |> assign(cluster: cluster)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({"cluster:save", %{"cluster" => cluster}}, socket) do
    new_path = ~p"/postgres/#{cluster}/show"

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={PostgresFormComponent}
        cluster={@cluster}
        id="new-cluster-form"
        action={:new}
      />
    </div>
    """
  end
end
