defmodule ControlServer.Repo.Migrations.CreateSystemBatteries do
  use Ecto.Migration

  def change do
    create table(:system_batteries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group, :string, null: false
      add :type, :string, null: false
      add :config, :map

      timestamps(type: :utc_datetime_usec)
    end

    create index(:system_batteries, [:type], unique: true)
  end
end
