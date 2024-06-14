defmodule ControlServerWeb.Live.IPAddressPoolNew do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias CommonCore.MetalLB.IPAddressPool
  alias ControlServerWeb.Live.IPAddressPoolFormComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :current_page, :net_sec)}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, assign(socket, :ip_address_pool, %IPAddressPool{})}
  end

  @impl Phoenix.LiveView
  def handle_info({"ip_address_pool:save", _}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ip_address_pools")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div>
      <.live_component
        module={IPAddressPoolFormComponent}
        id="new-ip-pool-form"
        ip_address_pool={@ip_address_pool}
        action={:new}
        save_target={self()}
        title="New IP Address Pool"
      />
    </div>
    """
  end
end
