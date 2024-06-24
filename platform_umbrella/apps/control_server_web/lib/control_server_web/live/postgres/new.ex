defmodule ControlServerWeb.Live.PostgresNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServerWeb.Live.PostgresFormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    # Pre-populate the databases and users with decent permissions
    cluster = KubeServices.SmartBuilder.new_postgres()

    {:ok,
     socket
     |> assign(:project_id, params["project_id"])
     |> assign(:current_page, :data)
     |> assign(:cluster, cluster)}
  end

  @impl Phoenix.LiveView
  def handle_info({"cluster:save", %{"cluster" => cluster}}, socket) do
    new_path = ~p"/postgres/#{cluster}/show"

    {:noreply, push_navigate(socket, to: new_path)}
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
        title="New Postgres Cluster"
        project_id={@project_id}
      />
    </div>
    """
  end
end
