defmodule ControlServerWeb.Live.IPAddressPoolIndex do
  @moduledoc """
  Live web app for database stored json configs.
  """
  use ControlServerWeb, {:live_view, layout: :sidebar}

  import ControlServerWeb.IPAddressPoolsTable

  alias ControlServer.MetalLB

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "MetalLB")
     |> assign(:current_page, :net_sec)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _session, socket) do
    with {:ok, {ip_address_pools, meta}} <- MetalLB.list_ip_address_pools(params) do
      {:noreply,
       socket
       |> assign(:meta, meta)
       |> assign(:ip_address_pools, ip_address_pools)
       |> assign(:form, to_form(meta))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _} = id |> MetalLB.get_ip_address_pool!() |> MetalLB.delete_ip_address_pool()
    {:noreply, push_navigate(socket, to: ~p"/ip_address_pools")}
  end

  @impl Phoenix.LiveView
  def handle_event("search", params, socket) do
    params = Map.delete(params, "_target")
    {:noreply, push_patch(socket, to: ~p"/ip_address_pools?#{params}")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.page_header title={@page_title} back_link={~p"/net_sec"}>
      <.button variant="dark" icon={:plus} link={new_url()}>
        New IP Address Pool
      </.button>
    </.page_header>

    <.panel title="IP Addresses">
      <:menu>
        <.table_search
          meta={@meta}
          fields={[name: [op: :ilike]]}
          placeholder="Filter by name"
          on_change="search"
        />
      </:menu>

      <.ip_address_pools_table rows={@ip_address_pools} meta={@meta} />
    </.panel>
    """
  end

  defp new_url, do: ~p"/ip_address_pools/new"
end
