defmodule ControlServerWeb.IPAddressPoolsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :rows, :list, default: []
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def ip_address_pools_table(assigns) do
    ~H"""
    <.table rows={@rows}>
      <:col :let={pool} :if={!@abbridged} label="ID"><%= pool.id %></:col>
      <:col :let={pool} label="Name"><%= pool.name %></:col>
      <:col :let={pool} label="Subnet"><%= pool.subnet %></:col>

      <:action :let={pool}>
        <.a navigate={show_url(pool)} variant="styled">Show</.a>
      </:action>
    </.table>
    """
  end

  defp show_url(pool), do: ~p"/ip_address_pools/#{pool}/show"
end
