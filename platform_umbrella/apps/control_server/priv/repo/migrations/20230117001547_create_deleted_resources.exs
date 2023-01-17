defmodule ControlServer.Repo.Migrations.CreateDeletedResources do
  use Ecto.Migration

  def change do
    create table(:deleted_resources) do
      add :kind, :string
      add :name, :string
      add :namespace, :string
      add :hash, :string

      add :content_addressable_resource_id,
          references(:content_addressable_resources, on_delete: :nothing)

      add :been_undeleted, :boolean

      timestamps()
    end

    create index(:deleted_resources, [:content_addressable_resource_id])
  end
end
