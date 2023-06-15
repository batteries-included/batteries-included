defmodule ControlServer.Repo.Migrations.CreateUmbrellaSnapshots do
  use Ecto.Migration

  def change do
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

    create table(:content_addressable_resources, primary_key: false) do
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
      add :content_addressable_resource_id, references(:content_addressable_resources)

      timestamps(type: :utc_datetime_usec)
    end

    create table(:deleted_resources) do
      add :kind, :string
      add :name, :string
      add :namespace, :string
      add :hash, :string

      add :content_addressable_resource_id,
          references(:content_addressable_resources, on_delete: :nothing)

      add :been_undeleted, :boolean

      timestamps(type: :utc_datetime_usec)
    end

    # Not sure about this one.
    # It was here before, but it might not be needed.
    create index(:deleted_resources, [:content_addressable_resource_id])

    # We generate the id from the hash.
    # They should be equally unique
    create unique_index(:content_addressable_resources, [:hash])

    # When going to the UI to show all resource paths for a snapshot
    # we get this list using the kube_snapshot_id
    create index(:resource_paths, [:kube_snapshot_id])

    # Each child snapshot is uniquely
    # has_one/belongs_to a single umbrella_snapshot
    create unique_index(:kube_snapshots, [:umbrella_snapshot_id])
    create unique_index(:keycloak_snapshots, [:umbrella_snapshot_id])
  end
end
