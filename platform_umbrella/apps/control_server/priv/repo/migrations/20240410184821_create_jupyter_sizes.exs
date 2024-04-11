defmodule ControlServer.Repo.Migrations.CreateJupyterSizes do
  use Ecto.Migration

  def change do
    alter table(:jupyter_lab_notebooks) do
      add :storage_size, :bigint
      add :storage_class, :string
      add :cpu_requested, :bigint
      add :cpu_limits, :integer
      add :memory_requested, :bigint
      add :memory_limits, :bigint
    end
  end
end
