defmodule ControlServerWeb.Live.RedisEdit do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  alias ControlServer.Redis
  alias ControlServerWeb.Live.Redis.FormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :failover_cluster, Redis.get_failover_cluster!(id))}
  end

  @impl true
  def handle_info({"failover_cluster:save", %{"failover_cluster" => failover_cluster}}, socket) do
    new_path = Routes.redis_path(socket, :index)
    Logger.debug("updated failover_cluster = #{inspect(failover_cluster)} new_path = #{new_path}")

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>Edit Redis Cluster</.title>
      </:title>
      <div>
        <.live_component
          module={FormComponent}
          failover_cluster={@failover_cluster}
          id={@failover_cluster.id || "edit-failover-cluster-form"}
          action={:edit}
          save_target={self()}
        />
      </div>
    </.layout>
    """
  end
end
