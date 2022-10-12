defmodule ControlServer.Repo.Migrations.CreateContentAddressableResources do
  use Ecto.Migration

  def change do
    create table(:content_addressable_resources, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :value, :map
      add :hash, :string

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:content_addressable_resources, [:hash])

    alter table(:resource_paths) do
      remove :resource_value
      remove :api_version
      remove :kind

      add :type, :string

      add :content_addressable_resource_id, references(:content_addressable_resources)
    end
  end
end
