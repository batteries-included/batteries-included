defmodule ControlServerWeb.IPAddressPoolsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :ip_address_pools, :list, default: []

  def ip_address_pools_table(assigns) do
    ~H"""
    <.table rows={@ip_address_pools}>
      <:col :let={pool} label="Name"><%= pool.name %></:col>
      <:col :let={pool} label="Subnet"><%= pool.subnet %></:col>

      <:action :let={pool}>
        <.a navigate={show_url(pool)} variant="styled">
          Show IP Pool
        </.a>
      </:action>
    </.table>
    """
  end

  defp show_url(pool), do: ~p"/ip_address_pools/#{pool}/show"
end
