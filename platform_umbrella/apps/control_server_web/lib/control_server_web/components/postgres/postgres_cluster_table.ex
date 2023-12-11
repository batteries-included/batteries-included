defmodule ControlServerWeb.PostgresClusterTable do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Postgres.Cluster

  attr :id, :string, default: "postgres-cluster-table"
  attr :rows, :list, required: true
  attr :abbridged, :boolean, default: false, doc: "the abbridged property control display of the id column and formatting"

  @spec postgres_clusters_table(map()) :: Phoenix.LiveView.Rendered.t()
  def postgres_clusters_table(assigns) do
    ~H"""
    <.table id={@id} rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={pg} :if={!@abbridged} label="ID"><%= pg.id %></:col>
      <:col :let={pg} label="Name"><%= pg.name %></:col>
      <:col :let={pg} label="Type"><%= pg.type %></:col>
      <:col :let={pg} label="User Count"><%= length(pg.users) %></:col>
      <:action :let={pg}>
        <.flex class="justify-items-center">
          <.action_icon
            to={show_url(pg)}
            icon={:eye}
            tooltip={"Show Postgres cluster " <> pg.name}
            id={"show_postgres_" <> pg.id}
          />
          <.action_icon
            to={edit_url(pg)}
            icon={:pencil}
            tooltip={"Edit cluster " <> pg.name}
            id={"edit_postgres_" <> pg.id}
          />
        </.flex>
      </:action>
    </.table>
    """
  end

  @spec show_url(Cluster.t()) :: String.t()
  defp show_url(%Cluster{} = cluster), do: ~p"/postgres/#{cluster}/show"

  @spec edit_url(Cluster.t()) :: String.t()
  defp edit_url(%Cluster{} = cluster), do: ~p"/postgres/#{cluster}/edit"
end
