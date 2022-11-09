defmodule ControlServer.Release do
  alias Ecto.Migrator

  require Logger

  @start_apps [:postgrex, :ecto, :ecto_sql, :control_server]
  @apps [:control_server]

  def migrate do
    load_app()
    Logger.debug("Starting Migrate")

    for app <- @apps do
      for repo <- repos(app) do
        {:ok, _, _} = Migrator.with_repo(repo, &Migrator.run(&1, :up, all: true))
      end
    end
  end

  def seed do
    load_app()
    Logger.info("Starting Seed")

    KubeExt.cluster_type()
    |> KubeExt.SnapshotApply.SeedStateSnapshot.seed()
    |> ControlServer.Seed.seed_from_snapshot()
  end

  def rollback(repo, version) do
    :ok = load_app()
    {:ok, _, _} = Migrator.with_repo(repo, &Migrator.run(&1, :down, to: version))
  end

  defp repos(app) do
    Application.fetch_env!(app, :ecto_repos) || []
  end

  defp load_app do
    IO.puts("Ensuring app is starte")

    Enum.each(@start_apps, fn app ->
      {:ok, _apps} = Application.ensure_all_started(app, :permanent)
    end)

    :ok
  end

  def createdb do
    # Start postgrex and ecto
    IO.puts("Starting dependencies...")

    # Start apps necessary for executing migrations
    :ok = load_app()

    for repo_app <- @apps do
      # Create every repo for every app that's to be started.
      for repo <- repos(repo_app) do
        :ok = ensure_repo_created(repo)
      end
    end

    IO.puts("createdb task done!")
  end

  defp ensure_repo_created(repo) do
    IO.puts("create #{inspect(repo)} database if it doesn't exist")

    case repo.__adapter__.storage_up(repo.config) do
      :ok -> :ok
      {:error, :already_up} -> :ok
      {:error, term} -> {:error, term}
    end
  end
end
