defmodule Mix.Tasks.HomeBase.Admin do
  @shortdoc "Add a user to the internal Batteries Included teams"
  @moduledoc """
  Adds a user by their email to all the internal Batteries Included teams as an admin.
  """

  use Mix.Task

  alias HomeBase.Accounts
  alias HomeBase.Accounts.AdminTeams
  alias HomeBase.Teams

  @shutdown {:shutdown, 1}

  def run(args) do
    case args do
      [email] ->
        Mix.Task.run_in_apps("app.start", [:home_base])
        add_user_to_teams(email)

      _ ->
        Mix.shell().error("Error: Please pass a user email as the first argument")

        exit(@shutdown)
    end
  end

  defp add_user_to_teams(email) do
    user = Accounts.get_user_by_email(email)
    team_ids = AdminTeams.admin_team_ids()

    unless user do
      Mix.shell().error("Error: Could not find a user for #{email}")

      exit(@shutdown)
    end

    results = Enum.map(team_ids, &add_user_to_team(user.email, &1))
    errors = Enum.filter(results, fn {status, result} -> unless(status == :ok, do: result) end)

    if errors == [] do
      Mix.shell().info("Success! #{email} has been added as an admin to #{Enum.count(results)} team(s)")
    else
      Mix.shell().error("Error: #{inspect(errors)}")

      exit(@shutdown)
    end
  end

  defp add_user_to_team(email, team_id) do
    team_id
    |> Teams.get_team!()
    |> Teams.create_team_role(%{invited_email: email, is_admin: true})
  end
end
