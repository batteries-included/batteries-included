defmodule ControlServerWeb.Live.IPAddressPoolNew do
  use ControlServerWeb, {:live_view, layout: :fresh}

  alias CommonCore.MetalLB.IPAddressPool
  alias ControlServerWeb.Live.IPAddressPoolFormComponent

  require Logger

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    ip_address_pool = %IPAddressPool{}
    {:noreply, assign(socket, :ip_address_pool, ip_address_pool)}
  end

  @impl Phoenix.LiveView
  def handle_info({"ip_address_pool:save", %{"ip_address_pool" => ip_address_pool}}, socket) do
    path = ~p"/ip_address_pools/#{ip_address_pool}/show"

    {:noreply, push_redirect(socket, to: path)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.h1>New IP Address Pool</.h1>
      <.live_component
        module={IPAddressPoolFormComponent}
        ip_address_pool={@ip_address_pool}
        id={@ip_address_pool.id || "new-ip-pool-form"}
        action={:new}
        save_target={self()}
      />
    </div>
    """
  end
end
