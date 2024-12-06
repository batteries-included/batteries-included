defmodule ControlServerWeb.Audit.EditVersionsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :meta, :map, default: nil
  attr :rows, :list, required: true

  attr :abridged, :boolean,
    default: false,
    doc: "the abridged property control display of the entity type and entity id column"

  attr :rest, :global

  def edit_versions_table(assigns) do
    ~H"""
    <.table
      id="edit-versions-table"
      variant={@meta && "paginated"}
      rows={@rows}
      meta={@meta}
      path={~p"/edit_versions"}
      row_click={&JS.navigate(show_url(&1))}
      {@rest}
    >
      <:col :let={edit_version} :if={!@abridged} field={:entity_id} label="Entity ID">
        {edit_version.entity_id}
      </:col>
      <:col :let={edit_version} :if={!@abridged} field={:entity_schema} label="Entity Type">
        {edit_version.entity_schema}
      </:col>
      <:col :let={edit_version} field={:action} label="Action">
        {edit_version.action}
      </:col>
      <:col :let={edit_version} field={:rollback} label="Was Rollback?">
        {edit_version.rollback}
      </:col>
      <:col :let={edit_version} field={:recorded_at} label="Recorded Time">
        <.relative_display time={edit_version.recorded_at} />
      </:col>
    </.table>
    """
  end

  defp show_url(edit_version), do: ~p"/edit_versions/#{edit_version.id}"
end
