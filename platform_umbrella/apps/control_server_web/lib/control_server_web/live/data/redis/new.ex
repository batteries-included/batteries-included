defmodule ControlServerWeb.Live.RedisNew do
  use ControlServerWeb, :live_view

  import ControlServerWeb.Layout

  alias ControlServer.Redis
  alias ControlServer.Redis.FailoverCluster
  # alias ControlServer.Services.RunnableService
  alias ControlServerWeb.Live.Redis.FormComponent

  require Logger

  @impl true
  def mount(_params, _session, socket) do
    failover_cluster = %FailoverCluster{}
    changeset = Redis.change_failover_cluster(failover_cluster)

    {:ok,
     socket
     |> assign(:failover_cluster, failover_cluster)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  def update(%{failover_cluster: failover_cluster} = assigns, socket) do
    Logger.info("Update")
    changeset = Redis.change_failover_cluster(failover_cluster)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_info({"failover_cluster:save", %{"failover_cluster" => failover_cluster}}, socket) do
    new_path = Routes.redis_path(socket, :index)
    Logger.debug("new_cluster = #{inspect(failover_cluster)} new_path = #{new_path}")
    # RunnableService.activate!(:database_public)

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout>
      <:title>
        <.title>New Cluster</.title>
      </:title>
      <h1>New Redis Cluster</h1>
      <div>
        <.live_component
          module={FormComponent}
          failover_cluster={@failover_cluster}
          id={@failover_cluster.id || "new-failover-cluster-form"}
          action={:new}
          save_target={self()}
        />
      </div>
    </.layout>
    """
  end
end
