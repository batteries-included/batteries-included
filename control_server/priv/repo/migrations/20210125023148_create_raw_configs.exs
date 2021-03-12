defmodule Server.Repo.Migrations.CreateRawConfigs do
  use Ecto.Migration

  def change do
    create table(:raw_configs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, :string
      add :content, :map

      timestamps()
    end
  end
end
