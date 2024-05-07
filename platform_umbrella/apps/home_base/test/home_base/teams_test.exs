defmodule HomeBase.TeamsTest do
  use HomeBase.DataCase

  alias HomeBase.Repo
  alias HomeBase.Teams
  alias HomeBase.Teams.Team
  alias HomeBase.Teams.TeamRole

  setup do
    user = insert(:user)
    team1 = insert(:team)
    team2 = insert(:team)
    team1_role = insert(:team_role, team: team1, user: user)
    team2_role = insert(:team_role, team: team2, user: user, is_admin: true)

    %{
      user: user,
      team1: team1,
      team2: team2,
      team1_role: team1_role,
      team2_role: team2_role
    }
  end

  ## Teams

  describe "create_team/2" do
    test "should create team and add user as admin", ctx do
      params = params_for(:team)

      assert {:ok, team} = Teams.create_team(ctx.user, params)
      assert team.name == params.name

      assert role = Repo.get_by(TeamRole, team_id: team.id, user_id: ctx.user.id)
      assert role.is_admin
    end

    test "should return error with invalid data", ctx do
      params = params_for(:team, name: "personal", op_email: "invalid")

      assert {:error, changeset} = Teams.create_team(ctx.user, params)
      assert changeset |> errors_on() |> Map.has_key?(:name)
      assert changeset |> errors_on() |> Map.has_key?(:op_email)
      refute Repo.get_by(Team, name: "personal")
    end
  end

  describe "update_team/2" do
    test "should update the team", ctx do
      params = %{op_email: "jane@doe.com"}

      assert {:ok, team} = Teams.update_team(ctx.team1, params)
      assert team.op_email == params.op_email
    end

    test "should return error with invalid data", ctx do
      params = %{op_email: "invalid"}

      assert {:error, changeset} = Teams.update_team(ctx.team1, params)
      assert changeset |> errors_on() |> Map.has_key?(:op_email)
      assert Repo.get(Team, ctx.team1.id) == ctx.team1
    end
  end

  describe "delete_team/2" do
    test "should delete the team and the team roles", ctx do
      assert {:ok, %Team{}} = Teams.delete_team(ctx.team1)
      refute Repo.get(Team, ctx.team1.id)
      refute Repo.get_by(TeamRole, team_id: ctx.team1.id)
    end
  end

  ## Team Roles

  describe "list_team_roles/1" do
    test "should list team roles", ctx do
      assert [role] = Teams.list_team_roles(ctx.team1)
      assert role.id == ctx.team1_role.id
    end
  end

  describe "create_team_role/2" do
    test "should create team role for existing user", ctx do
      user = insert(:user)
      params = params_for(:team_role, invited_email: user.email)

      assert {:ok, role} = Teams.create_team_role(ctx.team2, params)
      assert role.user_id == user.id
      refute role.invited_email
    end

    test "should create team role for new user", ctx do
      params = params_for(:team_role, invited_email: "jane@doe.com")

      assert {:ok, role} = Teams.create_team_role(ctx.team2, params)
      assert role.invited_email == "jane@doe.com"
      refute role.user_id
    end

    test "should return error with invalid data", ctx do
      params = params_for(:team_role, invited_email: "invalid")

      assert {:error, changeset} = Teams.create_team_role(ctx.team2, params)
      assert changeset |> errors_on() |> Map.has_key?(:invited_email)
    end

    test "should return error for user already on team", ctx do
      params = params_for(:team_role, invited_email: ctx.user.email)

      assert {:error, changeset} = Teams.create_team_role(ctx.team1, params)
      assert changeset |> errors_on() |> Map.has_key?(:user)
    end

    test "should return error for user already invited to team", ctx do
      insert(:team_role, team: ctx.team1, invited_email: "jane@doe.com")
      params = params_for(:team_role, invited_email: "jane@doe.com")

      assert {:error, changeset} = Teams.create_team_role(ctx.team1, params)
      assert changeset |> errors_on() |> Map.has_key?(:invited_email)
    end
  end

  describe "update_team_role/1" do
    test "should update the team role", ctx do
      params = %{is_admin: true}

      assert {:ok, role} = Teams.update_team_role(ctx.team1_role, params)
      assert role.is_admin
    end

    test "should return error with invalid data", ctx do
      params = %{invited_email: "invalid"}

      assert {:error, changeset} = Teams.update_team_role(ctx.team1_role, params)
      assert changeset |> errors_on() |> Map.has_key?(:invited_email)
      refute Repo.get!(TeamRole, ctx.team1_role.id).is_admin
    end
  end

  describe "delete_team_role/1" do
    test "should delete the team role", ctx do
      assert {:ok, %TeamRole{}} = Teams.delete_team_role(ctx.team1_role)
      refute Repo.get(TeamRole, ctx.team1_role.id)
    end

    test "should not delete team role if last admin", ctx do
      assert {:error, :last_admin} = Teams.delete_team_role(ctx.team2_role)
    end
  end
end
