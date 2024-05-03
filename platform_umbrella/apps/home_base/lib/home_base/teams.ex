defmodule HomeBase.Teams do
  @moduledoc false
  use HomeBase, :context

  alias HomeBase.Accounts
  alias HomeBase.Accounts.User
  alias HomeBase.Teams.Team
  alias HomeBase.Teams.TeamRole

  ## Teams

  def create_team(%User{} = user, attrs) do
    transaction =
      Multi.new()
      |> Multi.insert(:team, Team.changeset(%Team{}, attrs))
      |> Multi.insert(:role, fn %{team: team} ->
        Ecto.build_assoc(team, :roles, %{user: user, is_admin: true})
      end)
      |> Repo.transaction()

    case transaction do
      {:ok, %{team: team}} -> {:ok, team}
      {:error, :team, changeset, _} -> {:error, changeset}
    end
  end

  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  ## Team Roles

  def create_team_role(%Team{} = team, attrs) do
    %TeamRole{}
    |> TeamRole.changeset(attrs)
    |> Changeset.put_assoc(:team, team)
    |> match_email_to_user()
    |> Repo.insert()
  end

  def update_team_role(%TeamRole{} = role, attrs) do
    role
    |> TeamRole.changeset(attrs)
    |> Repo.update()
  end

  def delete_team_role(%TeamRole{} = role) do
    Repo.delete(role)
  end

  # Adds user into the changeset from the invited email,
  # if an account with that email exists.
  defp match_email_to_user(changeset) do
    email = Changeset.get_field(changeset, :invited_email)

    if user = Accounts.get_user_by_email(email) do
      changeset
      |> Changeset.put_change(:user_id, user.id)
      |> Changeset.delete_change(:invited_email)
    else
      changeset
    end
  end
end
