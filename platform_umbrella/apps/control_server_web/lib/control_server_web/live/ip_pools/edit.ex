defmodule ControlServerWeb.Live.IPAddressPoolEdit do
  @moduledoc false
  use ControlServerWeb, {:live_view, layout: :sidebar}

  alias ControlServer.MetalLB
  alias ControlServerWeb.Live.IPAddressPoolFormComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :current_page, :net_sec)}
  end

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _url, socket) do
    ip_address_pool = MetalLB.get_ip_address_pool!(id)

    {:noreply, assign(socket, :ip_address_pool, ip_address_pool)}
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
        id={@ip_address_pool.id}
        ip_address_pool={@ip_address_pool}
        action={:edit}
        save_target={self()}
        title="Edit IP Address Pool"
      />
    </div>
    """
  end
end
