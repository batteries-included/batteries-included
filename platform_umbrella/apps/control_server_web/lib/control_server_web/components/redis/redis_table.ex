defmodule ControlServerWeb.RedisTable do
  use ControlServerWeb, :html

  def show_url(cluster), do: ~p"/redis/#{cluster}/show"

  attr :failover_clusters, :list, default: []

  def redis_table(assigns) do
    ~H"""
    <.table id="redis-display-table" rows={@failover_clusters}>
      <:col :let={redis} label="Name"><%= redis.name %></:col>
      <:col :let={redis} label="Instances"><%= redis.num_redis_instances %></:col>
      <:col :let={redis} label="Sentinel Instances"><%= redis.num_sentinel_instances %></:col>
      <:action :let={redis}>
        <.link navigate={show_url(redis)} variant="styled">
          Show Redis Cluster
        </.link>
      </:action>
    </.table>
    """
  end
end
