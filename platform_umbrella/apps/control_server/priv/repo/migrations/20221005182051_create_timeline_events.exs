defmodule ControlServer.Repo.Migrations.CreateTimelineEvents do
  use Ecto.Migration

  def change do
    create table(:timeline_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :payload, :map

      timestamps(type: :utc_datetime_usec)
    end
  end
end
