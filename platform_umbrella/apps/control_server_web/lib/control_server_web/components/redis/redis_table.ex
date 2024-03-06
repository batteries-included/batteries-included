defmodule ControlServerWeb.RedisTable do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Redis.FailoverCluster

  attr :rows, :list, default: []
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  @spec redis_table(map()) :: Phoenix.LiveView.Rendered.t()
  def redis_table(assigns) do
    ~H"""
    <.table id="redis-display-table" rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={redis} :if={!@abbridged} label="ID"><%= redis.id %></:col>
      <:col :let={redis} label="Name"><%= redis.name %></:col>
      <:col :let={redis} label="Instances"><%= redis.num_redis_instances %></:col>
      <:col :let={redis} label="Sentinel Instances"><%= redis.num_sentinel_instances %></:col>
      <:action :let={redis}>
        <.flex>
          <.button
            variant="minimal"
            link={show_url(redis)}
            icon={:eye}
            id={"show_redis_" <> redis.id}
          />

          <.tooltip target_id={"show_redis_" <> redis.id}>
            Show Redis failover cluster <%= redis.name %>
          </.tooltip>

          <.button
            variant="minimal"
            link={edit_url(redis)}
            icon={:pencil}
            id={"edit_redis_" <> redis.id}
          />

          <.tooltip target_id={"edit_redis_" <> redis.id}>
            Edit cluster <%= redis.name %>
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  @spec show_url(FailoverCluster.t()) :: String.t()
  def show_url(%FailoverCluster{} = cluster), do: ~p"/redis/#{cluster}/show"

  @spec edit_url(FailoverCluster.t()) :: String.t()
  def edit_url(%FailoverCluster{} = cluster), do: ~p"/redis/#{cluster}/edit"
end
