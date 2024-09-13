defmodule Mix.Tasks.HomeBase.Batteries.Admin do
  @moduledoc false
  use Mix.Task

  alias HomeBase.Accounts
  alias HomeBase.Accounts.AdminTeams
  alias HomeBase.Teams

  def run(args) do
    case args do
      [email] ->
        Mix.Task.run_in_apps("app.start", [:home_base])
        add_user_to_teams(email)

      _ ->
        error("Please pass a user email as the first argument")
    end
  end

  defp add_user_to_teams(email) do
    user = Accounts.get_user_by_email(email) || error("Could not find a user for #{email}")
    team_ids = AdminTeams.admin_team_ids()

    results = Enum.map(team_ids, &add_user_to_team(user.email, &1))
    errors = Enum.filter(results, fn {status, result} -> unless(status == :ok, do: result) end)

    if errors == [] do
      Mix.shell().info("Success! #{email} has been added as an admin to #{Enum.count(results)} team(s)")
    else
      errors |> inspect() |> error()
    end
  end

  defp add_user_to_team(email, team_id) do
    team_id
    |> Teams.get_team!()
    |> Teams.create_team_role(%{invited_email: email, is_admin: true})
  end

  defp error(message) do
    Mix.shell().error("Error: #{message}")

    exit({:shutdown, 1})
  end
end
