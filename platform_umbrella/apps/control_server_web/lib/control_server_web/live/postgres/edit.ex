defmodule ControlServerWeb.Live.PostgresEdit do
  use ControlServerWeb, :live_view

  import ControlServerWeb.MenuLayout

  alias ControlServer.Postgres
  alias ControlServerWeb.Live.PostgresFormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :cluster, Postgres.get_cluster!(id))}
  end

  @impl true
  def handle_info({"cluster:save", %{"cluster" => cluster}}, socket) do
    {:noreply, push_redirect(socket, to: ~p"/postgres/clusters/#{cluster}/show")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.menu_layout>
      <:title>
        <.title>Edit Cluster</.title>
      </:title>
      <div>
        <.live_component
          module={PostgresFormComponent}
          cluster={@cluster}
          id={@cluster.id || "edit-cluster-form"}
          action={:edit}
          save_target={self()}
        />
      </div>
    </.menu_layout>
    """
  end
end
