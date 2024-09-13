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

        user = get_user(email)
        team_ids = AdminTeams.admin_team_ids()

        results = Enum.map(team_ids, &add_user_to_team(user.email, &1))
        errors = Enum.filter(results, fn {status, result} -> unless(status == :ok, do: result) end)

        if errors == [] do
          Logger.info("#{email} has been added as an admin to #{Enum.count(results)} team(s)")
        else
          error("Something went wrong: #{inspect(errors)}")
        end

      _ ->
        error("Please pass a user email as the first argument")
    end
  end

  defp get_user(email) do
    Accounts.get_user_by_email(email) || error("Could not find a user for #{email}")
  end

  defp add_user_to_team(email, team_id) do
    team_id
    |> Teams.get_team!()
    |> Teams.create_team_role(%{invited_email: email, is_admin: true})
  end

  defp error(message) do
    Logger.error(message)

    exit({:shutdown, 1})
  end
end
