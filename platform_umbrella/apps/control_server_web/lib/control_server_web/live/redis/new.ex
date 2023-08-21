defmodule ControlServerWeb.Live.RedisNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  alias CommonCore.Redis.FailoverCluster
  alias ControlServer.Batteries.Installer
  alias ControlServer.Redis
  alias ControlServerWeb.Live.Redis.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    failover_cluster = %FailoverCluster{num_redis_instances: 1, num_sentinel_instances: 1}
    changeset = Redis.change_failover_cluster(failover_cluster)

    {:ok,
     socket
     |> assign(:failover_cluster, failover_cluster)
     |> assign(:changeset, changeset)}
  end

  @impl Phoenix.LiveView
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

  @impl Phoenix.LiveView
  @spec handle_info({<<_::168>>, map}, Phoenix.LiveView.Socket.t()) ::
          {:noreply, Phoenix.LiveView.Socket.t()}
  def handle_info({"failover_cluster:save", %{"failover_cluster" => failover_cluster}}, socket) do
    new_path = ~p"/redis/#{failover_cluster}/show"
    Installer.install!(:redis)

    {:noreply, push_redirect(socket, to: new_path)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.h1>New Redis Cluster</.h1>
    <div>
      <.live_component
        module={FormComponent}
        failover_cluster={@failover_cluster}
        id={@failover_cluster.id || "new-failover-cluster-form"}
        action={:new}
        save_target={self()}
      />
    </div>
    """
  end
end
