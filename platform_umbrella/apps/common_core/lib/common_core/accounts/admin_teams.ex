defmodule CommonCore.Accounts.AdminTeams do
  @moduledoc """
  This module provides which teams are considered admin teams for
  Batteries Inclued home base.

  For prodution environment, the admin teams are defined by setting
  the environment variable `BATTERY_TEAM_IDS` to a comma-separated list
  of team ids (battery uuids).

  For development and test environments, we assume that the team from
  the bootstrap'd team.json file is the admin. However we also
  include the team ids from the `BATTERY_TEAM_IDS` environment
  variable. This should allows test teams in development.

  It is important however that production never uses the team.json
  file since we don't want to police the chance that it's
  created nefaiously.
  """
  alias CommonCore.Accounts.EnvFetcher
  alias CommonCore.Ecto.BatteryUUID
  alias CommonCore.Teams.Team
  alias CommonCore.Teams.TeamRole

  require CommonCore.Env

  @relative_path "../../../../bootstrap/team.json"

  @team_path :common_core
             |> :code.priv_dir()
             |> Path.join(@relative_path)

  @file_content @team_path
                |> File.read!()
                |> Jason.decode!()
                |> Team.new!()

  def bootstrap_team, do: @file_content

  def batteries_included_admin?(%TeamRole{team_id: team_id}) when not is_nil(team_id) do
    Enum.member?(admin_team_ids(), team_id)
  end

  def batteries_included_admin?(_role), do: false

  def admin_team_ids do
    do_admin_team_ids()
  end

  if CommonCore.Env.dev_env?() do
    # For development and test, we include the bootstrap team
    # that way developers don't have to start mix with the environment variables set.
    defp do_admin_team_ids do
      environment_team_ids() ++ [bootstrap_team().id]
    end
  else
    # for prod we only include the environment team ids
    defp do_admin_team_ids do
      environment_team_ids()
    end
  end

  defp environment_team_ids do
    # Take the environment variable and split it by commas
    # then cast each value to a BatteryUUID
    # keep only the {:ok, _} values
    EnvFetcher.get_env()
    |> String.split(",")
    |> Enum.map(&BatteryUUID.cast/1)
    |> Enum.filter(&match?({:ok, _}, &1))
    |> Enum.map(fn {:ok, id} -> id end)
    |> Enum.filter(&(is_nil(&1) == false))
  end
end
