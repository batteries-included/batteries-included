defmodule ControlServer.Repo.Migrations.CreateIpAddressPools do
  use Ecto.Migration

  def change do
    create table(:ip_address_pools, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :subnet, :string

      add :project_id, references(:system_projects)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ip_address_pools, [:name])
  end
end
