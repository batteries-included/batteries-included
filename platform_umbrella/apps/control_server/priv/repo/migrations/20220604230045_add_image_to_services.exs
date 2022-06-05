defmodule ControlServer.Repo.Migrations.AddImageToServices do
  use Ecto.Migration

  def change do
    alter table(:services) do
      add :image, :string
    end
  end
end
