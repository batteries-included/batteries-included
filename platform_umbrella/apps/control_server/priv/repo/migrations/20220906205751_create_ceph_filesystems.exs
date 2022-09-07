defmodule ControlServer.Repo.Migrations.CreateCephFilesystems do
  use Ecto.Migration

  def change do
    create table(:ceph_filesystems, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :include_erasure_encoded, :boolean, default: true, null: false

      timestamps(type: :utc_datetime_usec)
    end
  end
end
