defmodule ControlServer.Repo.Migrations.AddCredentialCopy do
  use Ecto.Migration

  def change do
    alter table(:pg_clusters) do
      add :credential_copies, :map
    end
  end
end
