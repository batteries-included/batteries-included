defmodule ControlServer.Repo.Migrations.CreateServices do
  use Ecto.Migration

  def change do
    create table(:knative_services, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :rollout_duration, :string
      add :oauth2_proxy, :boolean
      add :kube_internal, :boolean
      add :keycloak_realm, :string

      add :containers, :map
      add :init_containers, :map
      add :env_values, :map

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:knative_services, [:name])
  end
end
