defmodule HomeBase.Release do
  @moduledoc false
  alias Ecto.Migrator

  require Logger

  @start_apps [:postgrex, :ecto, :ecto_sql, :home_base]
  @apps [:home_base]

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
    :ok = load_app()

    if File.exists?(path) do
      # List the files then for every file in the
      # list if it matches the a different
      # pattern add the filename to a list for that type
      #
      # *team.json is for teams (Currently only one team is emitted)
      # *install.json is for installations
      # Everything else is ignored
      :ok = do_seed_team_and_install(path)
    else
      Logger.warning("File does not exist: #{path}. Skipping seed.")
    end

    Logger.debug("Seed task done!")
    :ok
  end

  def make_admin!(user_email) do
    :ok = load_app()
    user = HomeBase.Accounts.get_user_by_email(user_email)
    team_ids = CommonCore.Accounts.AdminTeams.admin_team_ids()

    if user == nil do
      Logger.warning("User #{user_email} not found. Skipping make_admin.")
      raise "User not found"
    end

    Logger.info("Making user #{user_email} an admin for teams: #{inspect(team_ids)}")

    # The user email must be @batteriesincl.com
    if !String.ends_with?(user.email, "batteriesincl.com") do
      Logger.warning("User #{user_email} is not a Batteries Included email. Skipping make_admin.")
      raise "User is not a Batteries Included email"
    end

    # The user must have confirmed their email
    if user.confirmed_at == nil do
      Logger.warning("User #{user_email} has not confirmed their email. Skipping make_admin.")
      raise "User has not confirmed their email"
    end

    Enum.each(team_ids, fn team_id ->
      team = HomeBase.Teams.get_team(team_id)

      {:ok, _} =
        HomeBase.Teams.create_team_role(team, %{invited_email: user.email, is_admin: true})
    end)
  end

  defp do_seed_team_and_install(path) do
    path
    |> File.ls!()
    |> Enum.reduce(%{teams: [], installations: []}, fn file_name, acc ->
      full_path = Path.join(path, file_name)

      cond do
        String.ends_with?(file_name, "team.json") ->
          %{acc | teams: [full_path | acc.teams]}

        String.ends_with?(file_name, "install.json") ->
          %{acc | installations: [full_path | acc.installations]}

        true ->
          acc
      end
    end)
    |> HomeBase.Seed.seed_files()
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
