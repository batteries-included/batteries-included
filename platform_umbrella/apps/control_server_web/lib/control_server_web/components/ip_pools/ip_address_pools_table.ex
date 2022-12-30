defmodule ControlServerWeb.IPAddressPoolsTable do
  use ControlServerWeb, :html

  attr :ip_address_pools, :list, default: []

  def ip_address_pools_table(assigns) do
    ~H"""
    <.table rows={@ip_address_pools}>
      <:col :let={pool} label="Name"><%= pool.name %></:col>
      <:col :let={pool} label="Subnet"><%= pool.subnet %></:col>
    </.table>
    """
  end
end
