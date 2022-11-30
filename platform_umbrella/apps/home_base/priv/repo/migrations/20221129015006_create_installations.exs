defmodule HomeBase.Repo.Migrations.CreateInstallations do
  use Ecto.Migration

  def change do
    create table(:installations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :slug, :string
      add :bootstrap_config, :map

      timestamps(type: :utc_datetime_usec)
    end
  end
end
