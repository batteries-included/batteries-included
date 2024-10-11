defmodule ControlServer.Repo.Migrations.AddAdditionalHostsTraditionalService do
  use Ecto.Migration

  def change do
    alter table(:traditional_services) do
      add :additional_hosts, :map
    end
  end
end
