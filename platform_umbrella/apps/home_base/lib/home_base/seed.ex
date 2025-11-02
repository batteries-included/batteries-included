defmodule HomeBase.Seed do
  @moduledoc false

  require Logger

  def seed_files(%{teams: teams, installations: installations}) do
    :ok = load_app()

    Enum.each(teams, &seed_team/1)
    Enum.each(installations, &seed_installation/1)

    Logger.info("Seed done!")
    :ok
  end

  def seed_static_projects do
    :ok = load_app()

    case HomeBase.BatteriesInstalls.list_internal_prod_installations() do
      [prod_install | _] ->
        prod_install.id
        |> HomeBase.Projects.StaticProjects.static_projects()
        |> Enum.each(fn {id, stored_project} ->
          case HomeBase.Projects.create_or_get_stored_project_snapshot(stored_project) do
            {:ok, _} ->
              Logger.info("Seeded static project #{id}")

            {:error, reason} ->
              Logger.error("Failed to seed static project #{id}: #{inspect(reason)}")
          end
        end)

      [] ->
        Logger.warning("No production installation found. Skipping static project seeding.")
    end
  end

  defp seed_team(team_file) do
    Logger.debug("Importing team from #{team_file}")
    team = team_file |> File.read!() |> Jason.decode!()

    case HomeBase.Teams.get_team(team["id"]) do
      nil -> create_entity(team, &HomeBase.Teams.create_team/1, "team")
      _existing -> Logger.info("Team #{team["id"]} already exists")
    end
  end

  defp seed_installation(install_file) do
    Logger.debug("Importing installation from #{install_file}")
    install = install_file |> File.read!() |> Jason.decode!()

    case HomeBase.CustomerInstalls.get_installation(install["id"]) do
      nil -> create_entity(install, &HomeBase.CustomerInstalls.create_installation/1, "installation")
      _existing -> Logger.info("Installation #{install["id"]} already exists")
    end
  end

  defp create_entity(entity, create_func, entity_type) do
    case create_func.(entity) do
      {:ok, _} ->
        Logger.info("Did not find #{entity_type} #{entity["id"]}. Created it.")

      {:error, reason} ->
        Logger.error("Failed to create #{entity_type} #{entity["id"]}: #{inspect(reason)}")
    end
  rescue
    e in Ecto.ConstraintError ->
      Logger.error("Failed to create #{entity_type} #{entity["id"]} due to constraint error: #{inspect(e)}")
  end

  @start_apps [:postgrex, :ecto, :ecto_sql, :home_base]
  defp load_app do
    Enum.each(@start_apps, fn app ->
      {:ok, _apps} = Application.ensure_all_started(app, :permanent)
    end)

    :ok
  end
end
