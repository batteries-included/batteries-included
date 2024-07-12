defmodule ControlServerWeb.Live.RedisEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.Redis
  alias ControlServerWeb.Live.Redis.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :current_page, :data)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign_failover_cluster(id)
     |> assign_page_title()}
  end

  defp assign_failover_cluster(socket, id) do
    assign(socket, :failover_cluster, Redis.get_failover_cluster!(id))
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "Edit Redis Cluster")
  end

  @impl Phoenix.LiveView
  def handle_info({"failover_cluster:save", %{"failover_cluster" => cluster}}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/redis/#{cluster}/show")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={FormComponent}
        failover_cluster={@failover_cluster}
        id={@failover_cluster.id || "edit-failover-cluster-form"}
        action={:edit}
        title={@page_title}
      />
    </div>
    """
  end
end
