defmodule ControlServerWeb.Live.PostgresEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Postgres
  alias ControlServerWeb.Live.PostgresFormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign_current_page()
     |> assign_title()
     |> assign_cluster(id)}
  end

  defp assign_current_page(socket) do
    assign(socket, current_page: :data)
  end

  defp assign_title(socket) do
    assign(socket, page_title: "Edit Postgres Cluster")
  end

  defp assign_cluster(socket, id) do
    assign(socket, cluster: Postgres.get_cluster!(id))
  end

  @impl Phoenix.LiveView
  def handle_info({"cluster:save", %{"cluster" => cluster}}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/postgres/#{cluster}/show")}
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
