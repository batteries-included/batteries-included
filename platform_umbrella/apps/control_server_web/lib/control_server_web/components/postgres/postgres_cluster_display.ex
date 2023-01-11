defmodule ControlServerWeb.PostgresClusterDisplay do
  use ControlServerWeb, :html

  def pg_cluster_display(assigns) do
    ~H"""
    <.table id="pg-cluster-table" rows={@clusters}>
      <:col :let={pg} label="Name"><%= pg.name %></:col>
      <:col :let={pg} label="Type"><%= pg.type %></:col>
      <:action :let={pg}>
        <.link navigate={show_url(pg)} variant="styled">
          Show Postgres
        </.link>
      </:action>
    </.table>
    """
  end

  defp show_url(cluster), do: ~p"/postgres/clusters/#{cluster}/show"
end
