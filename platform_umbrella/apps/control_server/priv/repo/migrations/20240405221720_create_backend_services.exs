defmodule ControlServer.Repo.Migrations.CreateBackendServices do
  use Ecto.Migration

  def change do
    create table(:backend_services, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :name, :string
      add :containers, :map
      add :init_containers, :map
      add :env_values, :map

      add :kube_deployment_type, :string
      add :num_instances, :integer

      add :storage_size, :bigint
      add :storage_class, :string
      add :cpu_requested, :bigint
      add :cpu_limits, :integer
      add :memory_requested, :bigint
      add :memory_limits, :bigint

      timestamps()
    end

    create unique_index(:backend_services, [:name])
  end
end
