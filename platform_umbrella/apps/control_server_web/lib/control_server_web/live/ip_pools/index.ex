defmodule ControlServerWeb.Live.IPAddressPoolIndex do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :fresh}

  import ControlServerWeb.IPAddressPoolsTable

  alias ControlServer.MetalLB

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :ip_address_pools, ip_address_pools())}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp ip_address_pools do
    MetalLB.list_ip_address_pools()
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.ip_address_pools_table ip_address_pools={@ip_address_pools} />
    """
  end
end
