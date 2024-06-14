defmodule HomeBase.Repo.Migrations.CreateInstallations do
  use Ecto.Migration

  def change do
    create table(:installations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :slug, :string

      add :usage, :string

      add :kube_provider, :string
      add :kube_provider_config, :map

      # Fields for SSO
      add :sso_enabled, :boolean
      add :initial_oauth_email, :string

      # Default size for the installation
      add :default_size, :string

      add :control_jwk, :map

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:installations, :slug)
  end
end
