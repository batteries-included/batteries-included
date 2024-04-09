defmodule ControlServer.Repo.Migrations.CreateBackendServices do
  use Ecto.Migration

  def change do
    create table(:backend_services, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :name, :string
      add :containers, :map
      add :init_containers, :map
      add :env_values, :map

      timestamps()
    end

    create unique_index(:backend_services, [:name])
  end
end
