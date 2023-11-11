defmodule ControlServerWeb.IPAddressPoolsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :rows, :list, default: []
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def ip_address_pools_table(assigns) do
    ~H"""
    <.table rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={pool} :if={!@abbridged} label="ID"><%= pool.id %></:col>
      <:col :let={pool} label="Name"><%= pool.name %></:col>
      <:col :let={pool} label="Subnet"><%= pool.subnet %></:col>

      <:action :let={pool}>
        <.action_icon
          to={show_url(pool)}
          icon={:eye}
          tooltip={"Show ip address pool " <> pool.name}
          id={"show_pool_" <> pool.id}
        />
      </:action>

      <:action :let={pool}>
        <.action_icon
          to={edit_url(pool)}
          icon={:pencil}
          tooltip={"Edit ip addresss pool " <> pool.name}
          id={"edit_pool_" <> pool.id}
        />
      </:action>
    </.table>
    """
  end

  defp show_url(pool), do: ~p"/ip_address_pools/#{pool}/show"
  defp edit_url(pool), do: ~p"/ip_address_pools/#{pool}/edit"
end
