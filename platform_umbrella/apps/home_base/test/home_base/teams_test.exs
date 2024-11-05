defmodule HomeBase.TeamsTest do
  use HomeBase.DataCase

  import HomeBase.CustomerInstallsFixtures

  alias CommonCore.Teams.Team
  alias CommonCore.Teams.TeamRole
  alias HomeBase.Repo
  alias HomeBase.Teams

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

    test "should create team with additional roles", ctx do
      user = insert(:user)
      params_role1 = params_for(:team_role, %{invited_email: user.email})
      params_role2 = params_for(:team_role, %{invited_email: "john@doe.com"})
      params = :team |> params_for() |> Map.put(:roles, %{"0" => params_role1, "1" => params_role2})

      assert {:ok, %{roles: [role1, role2]}} = Teams.create_team(ctx.user, params)
      assert role1.user_id == user.id
      refute role1.invited_email
      refute role2.user_id
      assert role2.invited_email == "john@doe.com"
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

  describe "delete_team/1" do
    test "should delete the team and the team roles", ctx do
      assert {:ok, %Team{}} = Teams.delete_team(ctx.team1)
      refute Repo.get(Team, ctx.team1.id)
      refute Repo.get_by(TeamRole, team_id: ctx.team1.id)
    end

    test "should return error if team still has installation", ctx do
      installation_fixture(team_id: ctx.team1.id)
      assert {:error, changeset} = Teams.delete_team(ctx.team1)
      assert changeset |> errors_on() |> Map.has_key?(:installations)
    end
  end

  describe "soft_delete_team/1" do
    test "should soft_delete the team but not the team roles", ctx do
      assert {:ok, %Team{}} = Teams.soft_delete_team(ctx.team1)
      refute Repo.get(Team, ctx.team1.id)
      assert %CommonCore.Teams.TeamRole{} = Repo.get_by(TeamRole, team_id: ctx.team1.id)

      # assert that there's still a record and that it's "soft" deleted
      found = Repo.get!(Team, ctx.team1.id, with_deleted: true)
      assert ctx.team1.id == found.id
    end
  end

  ## Team Roles

  describe "preload_team_roles/2" do
    test "should preload the team roles in the correct order", ctx do
      user1 = insert(:user)
      user2 = insert(:user)

      insert(:team_role, team: ctx.team1, invited_email: "foo@bar.com")
      insert(:team_role, team: ctx.team1, invited_email: "bar@baz.com")
      insert(:team_role, team: ctx.team1, user: user1)
      insert(:team_role, team: ctx.team1, user: user2, is_admin: true)

      assert %{roles: [role1, role2, role3, role4, role5]} = Teams.preload_team_roles(ctx.team1, ctx.user)
      assert role1.user_id == ctx.user.id
      assert role2.user_id == user2.id
      assert role3.user_id == user1.id
      assert role4.invited_email == "bar@baz.com"
      assert role5.invited_email == "foo@bar.com"
    end
  end

  describe "create_team_role/2" do
    test "should create team role for existing user", ctx do
      user = insert(:user)
      params = params_for(:team_role, invited_email: user.email)

      assert {:ok, role} = Teams.create_team_role(ctx.team2, params)
      assert role.user.id == user.id
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
      assert changeset |> errors_on() |> Map.has_key?(:invited_email)
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

  describe "soft_delete_team_role/1" do
    test "should soft_delete the role", ctx do
      assert {:ok, %TeamRole{}} = Teams.soft_delete_team_role(ctx.team1_role)
      refute Repo.get(TeamRole, ctx.team1_role.id)

      # assert that there's still a record and that it's "soft" deleted
      found = Repo.get!(TeamRole, ctx.team1_role.id, with_deleted: true)
      assert ctx.team1_role.id == found.id
    end
  end
end
