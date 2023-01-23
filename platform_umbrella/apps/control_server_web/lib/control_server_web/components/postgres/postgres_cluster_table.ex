defmodule ControlServerWeb.PostgresClusterTable do
  use ControlServerWeb, :html

  attr :id, :string, default: "postgres-cluster-table"
  attr :clusters, :list, required: true

  def postgres_clusters_table(assigns) do
    ~H"""
    <.table id={@id} rows={@clusters}>
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

  defp show_url(cluster), do: ~p"/postgres/#{cluster}/show"
end
