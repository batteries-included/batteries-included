defmodule ControlServerWeb.Audit.EditVersionsTable do
  @moduledoc false
  use ControlServerWeb, :html

  defp show_url(edit_version) do
    ~p"/edit_versions/#{edit_version.id}"
  end

  attr :edit_versions, :list, required: true
  attr :id, :string, default: "edit_versions-table"

  attr :abbridged, :boolean,
    default: false,
    doc: "the abbridged property control display of the entity type and entity id column"

  attr :rest, :global

  def edit_versions_table(assigns) do
    ~H"""
    <.table id={@id} rows={@edit_versions} {@rest}>
      <:col :let={edit_version} :if={!@abbridged} label="Entity ID">
        <%= edit_version.entity_id %>
      </:col>
      <:col :let={edit_version} :if={!@abbridged} label="Entity Type">
        <%= edit_version.entity_schema %>
      </:col>
      <:col :let={edit_version} label="Action">
        <%= edit_version.action %>
      </:col>
      <:col :let={edit_version} label="Was Rollback?">
        <%= edit_version.rollback %>
      </:col>
      <:col :let={edit_version} label="Recorded Time">
        <.relative_display time={edit_version.recorded_at} />
      </:col>

      <:action :let={edit_version}>
        <.flex class="justify-items-center">
          <.button
            variant="minimal"
            link={show_url(edit_version)}
            icon={:eye}
            id={"show_edit_version_" <> edit_version.id}
          />

          <.tooltip target_id={"show_edit_version_" <> edit_version.id}>
            Show Edit Version <%= edit_version.id %>
          </.tooltip>
        </.flex>
      </:action>
    </.table>
    """
  end
end
