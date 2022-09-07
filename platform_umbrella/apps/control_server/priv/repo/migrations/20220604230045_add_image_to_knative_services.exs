defmodule ControlServer.Repo.Migrations.AddImageToServices do
  use Ecto.Migration

  def change do
    alter table(:knative_services) do
      add :image, :string
    end
  end
end
