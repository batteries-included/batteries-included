defmodule ControlServerWeb.Live.RedisEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :fresh}

  alias ControlServer.Redis
  alias ControlServerWeb.Live.Redis.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply, assign(socket, :failover_cluster, Redis.get_failover_cluster!(id))}
  end

  @impl Phoenix.LiveView
  def handle_info({"failover_cluster:save", %{"failover_cluster" => cluster}}, socket) do
    {:noreply, push_redirect(socket, to: ~p"/redis/#{cluster}/show")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.h1>
      Edit Redis
      <:sub_header><%= @failover_cluster.name %></:sub_header>
    </.h1>
    <div>
      <.live_component
        module={FormComponent}
        failover_cluster={@failover_cluster}
        id={@failover_cluster.id || "edit-failover-cluster-form"}
        action={:edit}
        save_target={self()}
      />
    </div>
    """
  end
end
