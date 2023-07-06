defmodule WhatsUp.Repo.Migrations.CreateSites do
  use Ecto.Migration

  def change do
    create table(:sites) do
      add :url, :string
      add :timeout, :integer

      timestamps()
    end
  end
end
