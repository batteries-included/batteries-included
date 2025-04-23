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
     |> assign_redis_instance()
     |> assign_page_title()}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp assign_redis_instance(socket) do
    assign(socket, :redis_instance, KubeServices.SmartBuilder.new_redis())
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "New Redis Instance")
  end

  def update(%{redis_instance: _redis_instance} = assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl Phoenix.LiveView
  def handle_info({"redis_instance:save", %{"redis_instance" => redis_instance}}, socket) do
    new_path = ~p"/redis/#{redis_instance}/show"

    {:noreply, push_navigate(socket, to: new_path)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={FormComponent}
        redis_instance={@redis_instance}
        id={@redis_instance.id || "new-failover-cluster-form"}
        title={@page_title}
        action={:new}
        save_target={self()}
        project_id={@project_id}
      />
    </div>
    """
  end
end
