defmodule ControlServerWeb.PostgresClusterDisplay do
  use ControlServerWeb, :component

  alias ControlServerWeb.Router.Helpers, as: Routes

  def pg_cluster_display(assigns) do
    ~H"""
    <.table id="pg-cluster-table" rows={@clusters}>
      <:col :let={pg} label="Name"><%= pg.name %></:col>
      <:col :let={pg} label="Type"><%= pg.type %></:col>
      <:action :let={pg}>
        <.link navigate={show_url(pg)} type="styled">
          Show Postgres
        </.link>
      </:action>
    </.table>
    """
  end

  defp show_url(cluster),
    do: Routes.postgres_show_path(ControlServerWeb.Endpoint, :show, cluster.id)
end
