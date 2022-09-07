defmodule ControlServer.Repo.Migrations.CreateServices do
  use Ecto.Migration

  def change do
    create table(:knative_services, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string

      timestamps(type: :utc_datetime_usec)
    end
  end
end
