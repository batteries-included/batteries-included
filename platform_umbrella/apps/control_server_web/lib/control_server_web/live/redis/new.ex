defmodule ControlServerWeb.Live.RedisNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServerWeb.Live.Redis.FormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:project_id, params["project_id"])
     |> assign(:current_page, :data)
     |> assign_failover_cluster()
     |> assign_page_title()}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp assign_failover_cluster(socket) do
    assign(socket, :failover_cluster, KubeServices.SmartBuilder.new_redis())
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "New Redis Cluster")
  end

  def update(%{failover_cluster: _failover_cluster} = assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveView
  def handle_info({"failover_cluster:save", %{"failover_cluster" => failover_cluster}}, socket) do
    new_path = ~p"/redis/#{failover_cluster}/show"

    {:noreply, push_navigate(socket, to: new_path)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={FormComponent}
        failover_cluster={@failover_cluster}
        id={@failover_cluster.id || "new-failover-cluster-form"}
        title={@page_title}
        action={:new}
        save_target={self()}
        project_id={@project_id}
      />
    </div>
    """
  end
end
