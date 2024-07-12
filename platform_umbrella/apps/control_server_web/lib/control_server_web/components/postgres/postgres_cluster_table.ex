defmodule ControlServerWeb.PostgresClusterTable do
  @moduledoc false
  use ControlServerWeb, :html

  alias CommonCore.Postgres.Cluster
  alias CommonCore.Util.Memory

  attr :id, :string, default: "postgres-cluster-table"
  attr :rows, :list, required: true
  attr :abridged, :boolean, default: false, doc: "the abridged property control display of the id column and formatting"

  def postgres_clusters_table(assigns) do
    ~H"""
    <.table id={@id} rows={@rows} row_click={&JS.navigate(show_url(&1))}>
      <:col :let={pg} :if={!@abridged} label="ID"><%= pg.id %></:col>
      <:col :let={pg} label="Name"><%= pg.name %></:col>
      <:col :let={pg} :if={!@abridged} label="Type"><%= pg.type %></:col>
      <:col :let={pg} :if={!@abridged} label="Instances"><%= pg.num_instances %></:col>
      <:col :let={pg} :if={!@abridged} label="User Count"><%= length(pg.users) %></:col>
      <:col :let={pg} :if={!@abridged} label="Storage Size">
        <%= Memory.humanize(pg.storage_size) %>
      </:col>
      <:action :let={pg}>
        <.flex class="justify-items-center">
          <.button
            variant="minimal"
            link={edit_url(pg)}
            icon={:pencil}
            id={"edit_postgres_" <> pg.id}
          />

          <.tooltip target_id={"edit_postgres_" <> pg.id}>
            Edit Cluster
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end

  defp show_url(%Cluster{} = cluster), do: ~p"/postgres/#{cluster}/show"
  defp edit_url(%Cluster{} = cluster), do: ~p"/postgres/#{cluster}/edit"
end
