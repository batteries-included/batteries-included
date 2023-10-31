defmodule ControlServerWeb.Live.IPAddressPoolIndex do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServer.MetalLB
  import ControlServerWeb.IPAddressPoolsTable

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_page_title() |> assign_ip_address_pools()}
  end

  @impl Phoenix.LiveView
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp assign_page_title(socket) do
    assign(socket, :page_title, "IP Pools")
  end

  defp assign_ip_address_pools(socket) do
    assign(socket, :ip_address_pools, list_ip_address_pools())
  end

  defp new_url, do: ~p"/ip_address_pools/new"

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_button={%{link_type: "live_redirect", to: "/net_sec"}} />
    <.panel>
      <:title>MetalLB IP Addresses</:title>
      <:top_right>
        <.a navigate={new_url()} class="block">
          <.button class="w-full">
            New IP Address Pool
          </.button>
        </.a>
      </:top_right>
      <.ip_address_pools_table rows={@ip_address_pools} />
    </.panel>
    """
  end
end
