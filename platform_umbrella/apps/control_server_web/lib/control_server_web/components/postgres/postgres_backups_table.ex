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
              phx-click="restore_backup_modal"
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

  attr :restore_form, :map, default: nil

  def restore_backup_modal(assigns) do
    ~H"""
    <.form for={@restore_form} id="restore-form" phx-submit="do_restore">
      <.modal
        :if={@restore_form}
        show
        id="restore-backup-form-modal"
        size="lg"
        on_cancel={JS.push("close_restore_backup_modal")}
      >
        <:title>Cluster restore</:title>

        <.fieldset>
          <.input field={@restore_form[:backup_name]} type="hidden" />

          <.field>
            <:label>New Cluster Name</:label>
            <.input field={@restore_form[:new_name]} autocomplete="off" />
          </.field>
        </.fieldset>

        <:actions cancel="Cancel">
          <.button variant="primary" type="submit">Start restoration</.button>
        </:actions>
      </.modal>
    </.form>
    """
  end

  defp id(backup), do: get_in(backup, ~w(status backupId))
  defp started_at(backup), do: get_in(backup, ~w(status startedAt))
  defp stopped_at(backup), do: get_in(backup, ~w(status stoppedAt))
end
