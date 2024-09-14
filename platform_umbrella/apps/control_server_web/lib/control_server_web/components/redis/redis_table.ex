defmodule ControlServerWeb.RedisTable do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Redis.RedisInstance
  alias CommonCore.Util.Memory

  attr :rows, :list, default: []
  attr :meta, :map, default: nil
  attr :abridged, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"

  def redis_table(assigns) do
    ~H"""
    <.table
      id="redis-display-table"
      variant={@meta && "paginated"}
      rows={@rows}
      meta={@meta}
      path={~p"/redis"}
      row_click={&JS.navigate(show_url(&1))}
    >
      <:col :let={redis} :if={!@abridged} field={:id} label="ID"><%= redis.id %></:col>
      <:col :let={redis} field={:name} label="Name"><%= redis.name %></:col>
      <:col :let={redis} :if={!@abridged} field={:num_instances} label="Instances">
        <%= redis.num_instances %>
      </:col>
      <:col :let={redis} :if={!@abridged} field={:memory_limits} label="Memory Limits">
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

          <.button
            variant="minimal"
            link={show_url(redis)}
            icon={:eye}
            id={"redis_show_link_" <> redis.id}
            class="sm:hidden"
          />
          <.tooltip target_id={"redis_show_link_" <> redis.id}>
            Show Redis Cluster
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  def show_url(%RedisInstance{} = cluster), do: ~p"/redis/#{cluster}/show"
  def edit_url(%RedisInstance{} = cluster), do: ~p"/redis/#{cluster}/edit"
end
