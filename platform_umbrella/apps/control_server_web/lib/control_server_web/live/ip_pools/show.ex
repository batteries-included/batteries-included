defmodule ControlServerWeb.Live.IPAddressPoolShow do
  use ControlServerWeb, {:live_view, layout: :fresh}
  alias ControlServer.MetalLB

  @impl Phoenix.LiveView
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:id, id)
     |> assign(:ip_address_pool, MetalLB.get_ip_address_pool!(id))
     |> assign(:page_title, "IP Address Pool")}
  end

  @impl Phoenix.LiveView
  def handle_event("delete", _, socket) do
    {:ok, _} = MetalLB.delete_ip_address_pool(socket.assigns.ip_address_pool)

    {:noreply, push_redirect(socket, to: ~p"/ip_address_pools")}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.h1><%= @ip_address_pool.name %></.h1>
    <%= @ip_address_pool.subnet %>

    <.h2 variant="fancy">Actions</.h2>
    <.card>
      <div class="grid md:grid-cols-2 gap-6">
        <.a navigate={~p"/ip_address_pools/#{@ip_address_pool}/edit"} class="block">
          <.button class="w-full">
            Edit IP Address Pool
          </.button>
        </.a>

        <.button phx-click="delete" data-confirm="Are you sure?" class="w-full">
          Delete IP Address Pool
        </.button>
      </div>
    </.card>
    """
  end
end
