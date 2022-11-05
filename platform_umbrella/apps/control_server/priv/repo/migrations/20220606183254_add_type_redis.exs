defmodule ControlServer.Repo.Migrations.AddTypeRedis do
  use Ecto.Migration

  def change do
    alter table(:redis_clusters) do
      add :type, :string, null: false
    end
  end
end
