defmodule ControlServerWeb.Audit.EditVersionsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :edit_versions, :list, required: true
  attr :id, :string, default: "edit_versions-table"
  attr :rest, :global

  def edit_versions_table(assigns) do
    ~H"""
    <.table id={@id} rows={@edit_versions} {@rest}>
      <:col :let={edit_version} label="Entity Type">
        <%= edit_version.entity_schema %>
      </:col>
      <:col :let={edit_version} label="Action">
        <%= edit_version.action %>
      </:col>
      <:col :let={edit_version} label="Rollback?">
        <%= edit_version.rollback %>
      </:col>
      <:col :let={edit_version} label="When">
        <%= edit_version.recorded_at %>
      </:col>
    </.table>
    """
  end
end
