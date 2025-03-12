defmodule ControlServerWeb.Postgres.PostgresBackupsTable do
  @moduledoc false
  use ControlServerWeb, :html

  attr :class, :string, default: ""
  attr :backups, :list, required: true

  def backups_panel(assigns) do
    ~H"""
    <.panel title="Backups" class={@class}>
      <.table :if={@backups && @backups != []} id="postgres-backups-table" rows={@backups}>
        <:col :let={backup} label="ID">{get_in(backup, ~w(status backupId))}</:col>
        <:col :let={backup} label="Status">{get_in(backup, ~w(status phase))}</:col>
        <:col :let={backup} label="Start Time">
          <.relative_display time={get_in(backup, ~w(status startedAt))} />
        </:col>
        <:col :let={backup} label="Stopped Time">
          <.relative_display time={get_in(backup, ~w(status stoppedAt))} />
        </:col>
      </.table>
      <.light_text :if={@backups == []}>No backups</.light_text>
    </.panel>
    """
  end
end
