defmodule HomeBase.Teams do
  @moduledoc false
  use HomeBase, :context

  alias CommonCore.Accounts.User
  alias CommonCore.Teams.Team
  alias CommonCore.Teams.TeamRole
  alias HomeBase.Accounts

  ## Teams

  @spec get_team!(binary()) :: Ecto.Schema.t()
  def get_team!(id) do
    Team
    |> preload([:roles, :users, :installations])
    |> Repo.get!(id)
  end

  @spec get_team(binary()) :: Ecto.Schema.t() | nil
  def get_team(id) do
    Repo.get(Team, id)
  end

  def list_teams do
    Repo.all(Team)
  end

  def create_team(%User{} = user, attrs) do
    transaction =
      Multi.new()
      # Create team and match invited emails to user accounts
      |> Multi.insert(:team, fn %{} ->
        %Team{} |> Team.changeset(attrs) |> match_emails_to_users(user)
      end)
      # Create an admin role for the user creating the team
      |> Multi.insert(:role, fn %{team: team} ->
        Ecto.build_assoc(team, :roles, %{user: user, is_admin: true})
      end)
      |> Repo.transaction()

    case transaction do
      {:ok, %{team: team}} -> {:ok, team}
      {:error, :team, changeset, _} -> {:error, changeset}
    end
  end

  def create_team(attrs) do
    %Team{} |> Team.changeset(attrs) |> Repo.insert()
  end

  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  def delete_team(%Team{} = team) do
    team
    |> Changeset.change()
    # Prevent team from being deleted if there are still installations
    |> Changeset.no_assoc_constraint(:installations)
    |> Repo.delete()
  end

  ## Team Roles

  def preload_team_roles(%Team{} = team, %User{} = user) do
    query =
      from(r in TeamRole,
        order_by: [
          # Puts the current user at the top of the list when sorting
          asc: fragment("CASE ? WHEN ? THEN 1 ELSE 2 END", r.user_id, type(^user.id, CommonCore.Ecto.BatteryUUID)),
          desc: :is_admin,
          asc_nulls_first: :invited_email
        ]
      )

    Repo.preload(team, roles: {query, [:user]})
  end

  def create_team_role(%Team{} = team, attrs) do
    case %TeamRole{}
         |> TeamRole.changeset(attrs)
         |> Changeset.put_assoc(:team, team)
         |> match_email_to_user()
         |> Repo.insert() do
      # The settings page (which is what calls this function)
      # requires the role user to be preloaded.
      {:ok, role} -> {:ok, Repo.preload(role, :user)}
      error -> error
    end
  end

  def update_team_role(%TeamRole{} = role, attrs) do
    role
    |> TeamRole.changeset(attrs)
    |> Repo.update()
  end

  def delete_team_role(%TeamRole{is_admin: true} = role) do
    query =
      from team_role in TeamRole,
        where: team_role.id != ^role.id,
        where: team_role.team_id == ^role.team_id,
        where: not is_nil(team_role.user_id),
        where: team_role.is_admin,
        limit: 1

    # Don't allow the last admin on the team to leave
    case Repo.aggregate(query, :count) do
      0 -> {:error, :last_admin}
      _ -> Repo.delete(role)
    end
  end

  def delete_team_role(%TeamRole{} = role) do
    Repo.delete(role)
  end

  # Converts a role to a current user account from the
  # invited email, if an account with that email already
  # exists.
  defp match_email_to_user(changeset) do
    email = Changeset.get_field(changeset, :invited_email)

    if user = Accounts.get_user_by_email(email) do
      changeset
      |> Changeset.put_change(:user, user)
      |> Changeset.put_change(:user_id, user.id)
      |> Changeset.delete_change(:invited_email)
    else
      changeset
    end
  end

  # Converts multiple roles to a current user account from the
  # invited email, if an account with that email already exists.
  defp match_emails_to_users(changeset, current_user) do
    roles =
      changeset
      |> Changeset.get_field(:roles, [])
      # Remove the current user since they already get an admin role during team creation
      |> Enum.reject(&(!&1.invited_email || &1.invited_email == current_user.email))
      |> Enum.map(fn role ->
        if user = Accounts.get_user_by_email(role.invited_email) do
          role
          |> Map.put(:user, user)
          |> Map.put(:user_id, user.id)
          |> Map.put(:invited_email, nil)
        else
          role
        end
      end)

    Changeset.put_change(changeset, :roles, roles)
  end
end
