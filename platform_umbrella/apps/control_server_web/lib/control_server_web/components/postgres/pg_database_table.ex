defmodule ControlServerWeb.PgDatabaseTable do
  use ControlServerWeb, :html

  attr :databases, :list, required: true
  attr :id, :string, default: "postgres-databases-table"

  def pg_databases_table(assigns) do
    ~H"""
    <.table id={@id} rows={@databases}>
      <:col :let={db} label="Name"><%= db.name %></:col>
      <:col :let={db} label="Owner"><%= db.owner %></:col>
    </.table>
    """
  end
end
