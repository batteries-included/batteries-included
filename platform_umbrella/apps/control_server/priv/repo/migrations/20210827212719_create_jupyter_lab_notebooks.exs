defmodule ControlServer.Repo.Migrations.CreateJupyterLabNotebooks do
  use Ecto.Migration

  def change do
    create table(:jupyter_lab_notebooks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :image, :string

      timestamps(type: :utc_datetime_usec)
    end
  end
end
