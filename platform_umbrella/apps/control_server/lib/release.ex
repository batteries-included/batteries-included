defmodule ControlServer.Release do
  alias Ecto.Migrator

  @app :control_server

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Migrator.with_repo(repo, &Migrator.run(&1, :up, all: true))
    end
  end

  def seed do
    load_app()

    ControlServer.Services.activate_defaults()
    ControlServer.Postgres.insert_default_clusters()
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Migrator.with_repo(repo, &Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.ensure_all_started(@app, :permanent)
  end
end
