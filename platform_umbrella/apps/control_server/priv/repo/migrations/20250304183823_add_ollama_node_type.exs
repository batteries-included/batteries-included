defmodule ControlServer.Repo.Migrations.AddOllamaNodeType do
  use Ecto.Migration

  def change do
    alter table(:model_instances) do
      add :node_type, :string
    end
  end
end
