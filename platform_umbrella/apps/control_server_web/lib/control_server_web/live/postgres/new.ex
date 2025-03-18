defmodule ControlServerWeb.Live.PostgresNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.Postgres.Cluster
  alias ControlServer.Postgres
  alias ControlServerWeb.Live.PostgresFormComponent
  alias Ecto.Changeset

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"cluster_id" => id, "backup_name" => backup_name} = _params, _session, socket) do
    # get old cluster from db
    old_cluster = Postgres.get_cluster!(id, preload: [:project])

    # build our params from the existing cluster
    params =
      old_cluster
      |> Map.from_struct()
      |> Map.delete(:id)
      |> Map.delete(:name)
      |> Map.put(:restore_from_backup, backup_name)

    # create new cluster struct from params
    cluster = %Cluster{} |> Cluster.changeset(params) |> Changeset.apply_changes()

    {:ok,
     socket
     |> assign(:action, :recover)
     |> assign(:cluster, cluster)
     |> assign(:current_page, :data)
     |> assign(:project_id, cluster.project_id)
     |> assign(:title, "Recover Postgres Cluster")}
  end

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    # Pre-populate the databases and users with decent permissions
    cluster = KubeServices.SmartBuilder.new_postgres()

    {:ok,
     socket
     |> assign(:action, :new)
     |> assign(:cluster, cluster)
     |> assign(:current_page, :data)
     |> assign(:project_id, params["project_id"])
     |> assign(:title, "New Postgres Cluster")}
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
        action={@action}
        title={@title}
        project_id={@project_id}
      />
    </div>
    """
  end
end
