defmodule ControlServer.Repo.Migrations.AddTraditionalSvcMounts do
  use Ecto.Migration

  def change do
    alter table(:traditional_services) do
      add :mounts, :map
    end
  end
end
