defmodule ControlServer.Release do
  @moduledoc false
  alias Ecto.Migrator

  require Logger

  @start_apps [:postgrex, :ecto, :ecto_sql, :control_server]
  @apps [:control_server]

  def migrate do
    :ok = load_app()
    Logger.debug("Starting Migrate")

    for app <- @apps do
      for repo <- repos(app) do
        {:ok, _, _} = Migrator.with_repo(repo, &Migrator.run(&1, :up, all: true))
      end
    end
  end

  def createdb do
    # Start postgrex and ecto
    Logger.info("Starting createdb...")

    # Start apps necessary for executing migrations
    :ok = load_app()

    Enum.each(@apps, fn repo_app ->
      # Create every repo for every app that's to be started.
      repo_app
      |> repos()
      |> Enum.each(fn repo ->
        :ok = ensure_repo_created(repo)
      end)
    end)

    Logger.debug("createdb task done!")
  end

  def seed(path) do
    if File.exists?(path) do
      # Start apps necessary for executing migrations
      :ok = load_app()
      :ok = ControlServer.Seed.seed_from_path(path)
    else
      Logger.warning("File does not exist: #{path}. Skipping seed.")
    end
  end

  def rollback(repo, version) do
    :ok = load_app()
    {:ok, _, _} = Migrator.with_repo(repo, &Migrator.run(&1, :down, to: version))
  end

  defp repos(app) do
    case Application.fetch_env(app, :ecto_repos) do
      {:ok, repos} when is_list(repos) ->
        repos

      _ ->
        []
    end
  end

  defp load_app do
    Logger.debug("Ensuring app is started")

    Enum.each(@start_apps, fn app ->
      {:ok, _apps} = Application.ensure_all_started(app, :permanent)
    end)

    :ok
  end

  defp ensure_repo_created(repo) do
    Logger.info("Creating #{inspect(repo)} database if it doesn't exist")

    case repo.__adapter__().storage_up(repo.config()) do
      :ok -> :ok
      {:error, :already_up} -> :ok
      {:error, term} -> {:error, term}
    end
  end
end
