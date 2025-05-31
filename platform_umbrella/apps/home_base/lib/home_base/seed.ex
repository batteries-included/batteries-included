defmodule HomeBase.Seed do
  @moduledoc false

  require Logger

  def seed_files(%{teams: teams, installations: installations}) do
    :ok = load_app()
    # For each team file import the team
    for team_file <- teams do
      Logger.debug("Importing team from #{team_file}")
      team_json = File.read!(team_file)
      team = Jason.decode!(team_json)

      existing_team = HomeBase.Teams.get_team(team["id"])

      if existing_team do
        Logger.info("Team #{team["id"]} already exists")
      else
        {:ok, _} = HomeBase.Teams.create_team(team)
        Logger.info("Did not find team #{team["id"]}. Created it.")
      end
    end

    # Now the installations
    for install_file <- installations do
      Logger.debug("Importing installation from #{install_file}")
      install_json = File.read!(install_file)
      install = Jason.decode!(install_json)

      existing_install = HomeBase.CustomerInstalls.get_installation(install["id"])

      if existing_install do
        Logger.info("Installation #{install["id"]} already exists")
      else
        {:ok, _} = HomeBase.CustomerInstalls.create_installation(install)
        Logger.info("Did not find installation #{install["id"]}. Created it.")
      end
    end

    Logger.info("Seed done!")
    :ok
  end

  def seed_static_projects do
    :ok = load_app()

    Logger.info("Seeding static projects")
  end

  @start_apps [:postgrex, :ecto, :ecto_sql, :home_base]
  defp load_app do
    Enum.each(@start_apps, fn app ->
      {:ok, _apps} = Application.ensure_all_started(app, :permanent)
    end)

    :ok
  end
end
