defmodule ControlServerWeb.RedisTable do
  @moduledoc false
  use ControlServerWeb, :html

  def show_url(cluster), do: ~p"/redis/#{cluster}/show"

  attr :rows, :list, default: []
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def redis_table(assigns) do
    ~H"""
    <.table id="redis-display-table" rows={@rows}>
      <:col :let={redis} :if={!@abbridged} label="ID"><%= redis.id %></:col>
      <:col :let={redis} label="Name"><%= redis.name %></:col>
      <:col :let={redis} label="Instances"><%= redis.num_redis_instances %></:col>
      <:col :let={redis} label="Sentinel Instances"><%= redis.num_sentinel_instances %></:col>
      <:action :let={redis}>
        <.a navigate={show_url(redis)} variant="styled">Show</.a>
      </:action>
    </.table>
    """
  end
end
