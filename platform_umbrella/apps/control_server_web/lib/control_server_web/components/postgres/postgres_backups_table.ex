defmodule ControlServerWeb.Postgres.PostgresBackupsTable do
  @moduledoc false
  use ControlServerWeb, :html

  import CommonCore.Resources.FieldAccessors
  import ControlServerWeb.ResourceHTMLHelper

  attr :class, :string, default: ""
  attr :backups, :list, required: true
  attr :restore_enabled, :boolean, default: false

  def backups_panel(assigns) do
    ~H"""
    <.panel title="Backups" class={@class}>
      <.table :if={@backups && @backups != []} id="postgres-backups-table" rows={@backups}>
        <:col :let={backup} label="ID">{id(backup)}</:col>
        <:col :let={backup} label="Status">{phase(backup)}</:col>
        <:col :let={backup} label="Started"><.relative_display time={started_at(backup)} /></:col>
        <:col :let={backup} label="Stopped"><.relative_display time={stopped_at(backup)} /></:col>
        <:action :let={backup} :if={@restore_enabled}>
          <.flex>
            <.button
              variant="minimal"
              icon={:arrow_path}
              id={"restore_" <> to_html_id(backup)}
              phx-click="restore"
              phx-value-backup_name={name(backup)}
            />
            <.tooltip target_id={"restore_" <> to_html_id(backup)}>
              Restore from backup {name(backup)}
            </.tooltip>
          </.flex>
        </:action>
      </.table>
      <.light_text :if={@backups == []}>No backups</.light_text>
    </.panel>
    """
  end

  defp id(backup), do: get_in(backup, ~w(status backupId))
  defp started_at(backup), do: get_in(backup, ~w(status startedAt))
  defp stopped_at(backup), do: get_in(backup, ~w(status stoppedAt))
end
