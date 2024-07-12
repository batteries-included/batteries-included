defmodule ControlServerWeb.RedisTable do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Redis.FailoverCluster
  alias CommonCore.Util.Memory

  attr :rows, :list, default: []
  attr :abridged, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"

  def redis_table(assigns) do
    ~H"""
    <.table id="redis-display-table" rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={redis} :if={!@abridged} label="ID"><%= redis.id %></:col>
      <:col :let={redis} label="Name"><%= redis.name %></:col>
      <:col :let={redis} :if={!@abridged} label="Instances"><%= redis.num_redis_instances %></:col>
      <:col :let={redis} :if={!@abridged} label="Sentinel Instances">
        <%= redis.num_sentinel_instances %>
      </:col>
      <:col :let={redis} :if={!@abridged} label="Memory Limits">
        <%= Memory.humanize(redis.memory_limits) %>
      </:col>
      <:action :let={redis}>
        <.flex>
          <.button
            variant="minimal"
            link={edit_url(redis)}
            icon={:pencil}
            id={"edit_redis_" <> redis.id}
          />

          <.tooltip target_id={"edit_redis_" <> redis.id}>
            Edit Cluster
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  def show_url(%FailoverCluster{} = cluster), do: ~p"/redis/#{cluster}/show"
  def edit_url(%FailoverCluster{} = cluster), do: ~p"/redis/#{cluster}/edit"
end
