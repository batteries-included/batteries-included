defmodule Mix.Tasks.HomeBase.Batteries.Admin do
  @moduledoc false
  use Mix.Task

  alias HomeBase.Accounts
  alias HomeBase.Accounts.AdminTeams
  alias HomeBase.Teams

  require Logger

  def run(args) do
    case args do
      [email] ->
        Mix.Task.run_in_apps("app.start", [:home_base])

        if Accounts.get_user_by_email(email) do
          team_ids = AdminTeams.admin_team_ids()
          results = Enum.map(team_ids, &add_user_to_team(email, &1))

          Logger.info("#{email} has been added as an admin to #{Enum.count(results)} team(s)")
        else
          Logger.error("Could not find user for #{email}")
        end

      _ ->
        Logger.error("Please pass a user email as the first argument")
    end
  end

  defp add_user_to_team(email, team_id) do
    team_id
    |> Teams.get_team!()
    |> Teams.create_team_role(%{invited_email: email, is_admin: true})
  end
end
