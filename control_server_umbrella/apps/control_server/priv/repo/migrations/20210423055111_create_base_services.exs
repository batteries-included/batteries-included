defmodule ControlServer.Repo.Migrations.CreateBaseServices do
  use Ecto.Migration

  def change do
    create table(:base_services, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :root_path, :string, null: false
      add :service_type, :string, null: false
      add :is_active, :boolean, default: false, null: false
      add :config, :map

      timestamps()
    end
  end
end
