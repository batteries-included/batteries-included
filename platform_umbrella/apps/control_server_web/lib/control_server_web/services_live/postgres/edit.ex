defmodule ControlServerWeb.ServicesLive.PostgresEdit do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  alias ControlServer.Postgres
  alias ControlServerWeb.ServicesLive.Postgres.FormComponent

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
    new_path = Routes.services_postgres_home_path(socket, :index)
    Logger.debug("updated cluster = #{inspect(cluster)} new_path = #{new_path}")

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Edit Cluster</.title>
      </:title>
      <div>
        <.live_component
          module={FormComponent}
          cluster={@cluster}
          id={@cluster.id || "edit-cluster-form"}
          action={:edit}
          save_target={self()}
        />
      </div>
    </.layout>
    """
  end
end
