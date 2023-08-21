defmodule ControlServerWeb.PostgresClusterTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :id, :string, default: "postgres-cluster-table"
  attr :rows, :list, required: true

  def postgres_clusters_table(assigns) do
    ~H"""
    <.table id={@id} rows={@rows}>
      <:col :let={pg} label="Name"><%= pg.name %></:col>
      <:col :let={pg} label="Type"><%= pg.type %></:col>
      <:col :let={pg} label="User Count"><%= length(pg.users) %></:col>
      <:col :let={pg} label="DB Count"><%= length(pg.users) %></:col>
      <:action :let={pg}>
        <.a navigate={show_url(pg)} variant="styled">
          Show Postgres
        </.a>
      </:action>
    </.table>
    """
  end

  defp show_url(cluster), do: ~p"/postgres/#{cluster}/show"
end
