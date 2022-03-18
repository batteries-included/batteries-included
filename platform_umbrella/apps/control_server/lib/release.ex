defmodule ControlServer.Release do
  alias Ecto.Migrator

  @start_apps [:postgrex, :ecto, :ecto_sql, :control_server]
  @apps [:control_server]

  def migrate do
    load_app()

    IO.puts("Starting Migrate")

    for app <- @apps do
      for repo <- repos(app) do
        {:ok, _, _} = Migrator.with_repo(repo, &Migrator.run(&1, :up, all: true))
      end
    end
  end

  def seed do
    load_app()
    IO.puts("Starting Seed")

    ControlServer.Services.activate_defaults()
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Migrator.with_repo(repo, &Migrator.run(&1, :down, to: version))
  end

  defp repos(app) do
    Application.fetch_env!(app, :ecto_repos) || []
  end

  defp load_app do
    IO.puts("Ensuring app is starte")

    Enum.map(@start_apps, fn app ->
      Application.ensure_all_started(app, :permanent)
    end)
  end

  def createdb do
    # Start postgrex and ecto
    IO.puts("Starting dependencies...")

    # Start apps necessary for executing migrations
    load_app()

    for app <- @apps do
      for repo <- repos(app) do
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
