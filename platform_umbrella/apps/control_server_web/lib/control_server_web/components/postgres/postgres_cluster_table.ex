defmodule ControlServerWeb.PostgresClusterTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :id, :string, default: "postgres-cluster-table"
  attr :rows, :list, required: true
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  def postgres_clusters_table(assigns) do
    ~H"""
    <.table id={@id} rows={@rows}>
      <:col :let={pg} :if={!@abbridged} label="ID"><%= pg.id %></:col>
      <:col :let={pg} label="Name"><%= pg.name %></:col>
      <:col :let={pg} label="Type"><%= pg.type %></:col>
      <:col :let={pg} label="User Count"><%= length(pg.users) %></:col>
      <:action :let={pg}>
        <.a navigate={show_url(pg)} variant="styled">
          Show
        </.a>
      </:action>
    </.table>
    """
  end

  defp show_url(cluster), do: ~p"/postgres/#{cluster}/show"
end
