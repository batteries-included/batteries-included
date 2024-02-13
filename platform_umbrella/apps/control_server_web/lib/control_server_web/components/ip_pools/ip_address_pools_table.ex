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
        <.flex>
          <.action_icon
            phx-click="delete"
            phx-value-id={pool.id}
            data-confirm={"Are you sure you want to delete the `#{pool.name}` pool?"}
            icon={:trash}
            tooltip="Delete IP Address Pool"
            id={"delete_pool_" <> pool.id}
          />

          <.action_icon
            to={edit_url(pool)}
            icon={:pencil}
            tooltip="Edit IP Addresss Pool"
            id={"edit_pool_" <> pool.id}
          />
        </.flex>
      </:action>
    </.table>
    """
  end

  defp edit_url(pool), do: ~p"/ip_address_pools/#{pool}/edit"
end
