defmodule ControlServer.Repo.Migrations.Unify do
  use Ecto.Migration

  def change do
    create table(:projects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :description, :text

      timestamps(type: :utc_datetime_usec)
    end

    create table(:pg_clusters, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :storage_size, :bigint
      add :storage_class, :string
      add :cpu_requested, :bigint
      add :cpu_limits, :integer
      add :memory_requested, :bigint
      add :memory_limits, :bigint
      add :num_instances, :integer
      add :type, :string
      add :users, :map
      add :password_versions, :map
      add :database, :map

      add :project_id, references(:projects, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:pg_clusters, [:type, :name])

    create table(:jupyter_lab_notebooks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :image, :string

      add :storage_size, :bigint
      add :storage_class, :string
      add :cpu_requested, :bigint
      add :cpu_limits, :integer
      add :memory_requested, :bigint
      add :memory_limits, :bigint

      add :env_values, :map

      add :project_id, references(:projects, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

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

      add :project_id, references(:projects, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:knative_services, [:name])

    create table(:redis_instances, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :type, :string, null: false

      add :instance_type, :string
      add :storage_size, :bigint
      add :storage_class, :string

      add :num_instances, :integer
      add :cpu_requested, :integer
      add :cpu_limits, :bigint
      add :memory_requested, :bigint
      add :memory_limits, :bigint

      add :project_id, references(:projects, on_delete: :nilify_all)
      add :replication_redis_instance_id, references(:redis_instances)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:redis_instances, [:type, :name])

    create table(:ip_address_pools, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :subnet, :string

      add :project_id, references(:projects, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ip_address_pools, [:name])

    create table(:ferret_services, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :name, :string
      add :instances, :integer

      add :cpu_requested, :bigint
      add :cpu_limits, :bigint

      add :memory_requested, :bigint
      add :memory_limits, :bigint

      add :postgres_cluster_id, references(:pg_clusters, on_delete: :delete_all, type: :binary_id)
      add :project_id, references(:projects, on_delete: :nilify_all)

      timestamps(type: :utc_datetime_usec)
    end

    create index(:ferret_services, [:postgres_cluster_id])
    create unique_index(:ferret_services, [:name])

    create table(:traditional_services, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :name, :string
      add :containers, :map
      add :init_containers, :map
      add :env_values, :map
      add :ports, :map
      add :volumes, :map

      add :kube_internal, :boolean
      add :kube_deployment_type, :string
      add :num_instances, :integer

      add :storage_size, :bigint
      add :storage_class, :string
      add :cpu_requested, :bigint
      add :cpu_limits, :integer
      add :memory_requested, :bigint
      add :memory_limits, :bigint

      add :project_id, references(:projects, on_delete: :nilify_all)

      timestamps()
    end

    create unique_index(:traditional_services, [:name])

    create table(:system_batteries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group, :string, null: false
      add :type, :string, null: false
      add :config, :map

      timestamps(type: :utc_datetime_usec)
    end

    create index(:system_batteries, [:type], unique: true)

    create table(:timeline_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :payload, :map

      timestamps(type: :utc_datetime_usec)
    end

    create table(:edit_versions, primary_key: false) do
      add :id, :uuid, primary_key: true

      # The patch in Erlang External Term Format
      add :patch, :binary

      # supports UUID and other types as well
      add :entity_id, :uuid

      # name of the table the entity is in
      add :entity_schema, :string

      # type of the action that has happened to the entity (created, updated, deleted)
      add :action, :string

      # when has this happened
      add :recorded_at, :utc_datetime

      # was this change part of a rollback?
      add :rollback, :boolean, default: false
    end

    create index(:edit_versions, [:entity_schema, :entity_id])

    create table(:umbrella_snapshots, primary_key: false) do
      add :id, :uuid, primary_key: true

      timestamps(type: :utc_datetime_usec)
    end

    create table(:keycloak_snapshots, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :status, :string

      add :umbrella_snapshot_id,
          references(:umbrella_snapshots, on_delete: :delete_all, type: :uuid)

      timestamps(type: :utc_datetime_usec)
    end

    create table(:kube_snapshots, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :status, :string

      add :umbrella_snapshot_id,
          references(:umbrella_snapshots, on_delete: :delete_all, type: :uuid)

      timestamps(type: :utc_datetime_usec)
    end

    create table(:documents, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :value, :map
      add :hash, :string

      timestamps(type: :utc_datetime_usec)
    end

    create table(:resource_paths, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :path, :string

      add :hash, :string
      add :name, :string
      add :namespace, :string

      add :type, :string

      add :is_success, :boolean
      add :apply_result, :string

      add :kube_snapshot_id, references(:kube_snapshots, on_delete: :delete_all, type: :uuid)
      add :document_id, references(:documents, on_delete: :nothing)

      timestamps(type: :utc_datetime_usec)
    end

    create table(:deleted_resources) do
      add :kind, :string
      add :name, :string
      add :namespace, :string
      add :hash, :string

      add :document_id, references(:documents, on_delete: :nothing)

      add :been_undeleted, :boolean

      timestamps(type: :utc_datetime_usec)
    end

    create table(:keycloak_actions) do
      add :action, :string
      add :type, :string

      add :realm, :string

      add :apply_result, :string
      add :is_success, :boolean

      add :document_id, references(:documents, on_delete: :nothing)

      add :keycloak_snapshot_id,
          references(:keycloak_snapshots, on_delete: :delete_all, type: :uuid)

      timestamps(type: :utc_datetime_usec)
    end

    # We generate the id from the hash.
    # They should be equally unique
    create unique_index(:documents, [:hash])

    # When going to the UI to show all resource paths for a snapshot
    # we get this list using the kube_snapshot_id
    create index(:resource_paths, [:kube_snapshot_id])

    # Each child snapshot is uniquely
    # has_one/belongs_to a single umbrella_snapshot
    create unique_index(:kube_snapshots, [:umbrella_snapshot_id])
    create unique_index(:keycloak_snapshots, [:umbrella_snapshot_id])

    # Each acion belongs to a snapshot and we'll need to list them
    create index(:keycloak_actions, [:keycloak_snapshot_id])

    # For when we want to show content addressable info
    #
    create index(:deleted_resources, [:document_id])
    create index(:keycloak_actions, [:document_id])
    create index(:resource_paths, [:document_id])
  end
end
