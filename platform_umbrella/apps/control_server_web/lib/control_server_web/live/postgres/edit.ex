defmodule ControlServerWeb.Live.PostgresEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Postgres
  alias ControlServerWeb.Live.PostgresFormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    {:ok, assign(socket, current_page: :datastores, cluster: Postgres.get_cluster!(id))}
  end

  @impl Phoenix.LiveView
  def handle_info({"cluster:save", %{"cluster" => cluster}}, socket) do
    {:noreply, push_redirect(socket, to: ~p"/postgres/#{cluster}/show")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.live_component
      module={PostgresFormComponent}
      cluster={@cluster}
      id={@cluster.id || "edit-cluster-form"}
      action={:edit}
      save_target={self()}
      title={"Editing #{@cluster.name}"}
    />
    """
  end
end
