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
     |> assign_redis_instance(id)
     |> assign_page_title()}
  end

  defp assign_redis_instance(socket, id) do
    assign(socket, :redis_instance, Redis.get_redis_instance!(id))
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "Edit Redis Instance")
  end

  @impl Phoenix.LiveView
  def handle_info({"redis_instance:save", %{"redis_instance" => cluster}}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/redis/#{cluster}/show")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={FormComponent}
        redis_instance={@redis_instance}
        id={@redis_instance.id || "edit-failover-cluster-form"}
        action={:edit}
        title={@page_title}
      />
    </div>
    """
  end
end
