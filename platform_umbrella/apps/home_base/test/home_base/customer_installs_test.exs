defmodule HomeBase.CustomerInstallsTest do
  use HomeBase.DataCase

  alias HomeBase.CustomerInstalls
  alias HomeBase.Repo

  describe "installations" do
    import HomeBase.CustomerInstallsFixtures

    alias CommonCore.Installation

    @invalid_attrs %{bootstrap_config: nil, slug: "invalid slug"}

    test "list_installations/0 returns all installations" do
      installation = installation_fixture()
      assert CustomerInstalls.list_installations() == [installation]
    end

    test "list_installations/1 returns all installations for a user" do
      user = insert(:user)
      installation = installation_fixture(user_id: user.id)

      assert CustomerInstalls.list_installations(user) == [installation]
    end

    test "list_installations/1 returns all installations for a team" do
      team = insert(:team)
      installation = installation_fixture(team_id: team.id)

      assert CustomerInstalls.list_installations(team) == [installation]
    end

    test "list_recent_installations/2 returns all recent installations for a user" do
      user = insert(:user)
      team = insert(:team)

      insert(:team_role, user_id: user.id, team_id: team.id)

      user_installation = installation_fixture(user_id: user.id)
      team_installation = installation_fixture(team_id: team.id)

      assert [installation1, installation2] = CustomerInstalls.list_recent_installations(user)
      assert installation1.id == team_installation.id
      assert installation2.id == user_installation.id
    end

    test "count_installations/1 returns the count for a user" do
      user = insert(:user)
      team = insert(:team)

      insert(:team_role, user_id: user.id, team_id: team.id)

      installation_fixture(user_id: user.id)
      installation_fixture(team_id: team.id)

      assert CustomerInstalls.count_installations(user) == 2
    end

    test "count_installations/1 returns the count for a team" do
      team = insert(:team)
      installation_fixture(team_id: team.id)
      installation_fixture(team_id: team.id)

      assert CustomerInstalls.count_installations(team) == 2
    end

    test "count_teams/1 returns the count for a user" do
      user = insert(:user)
      team = insert(:team)

      insert(:team_role, user_id: user.id, team_id: team.id)

      assert CustomerInstalls.count_teams(user) == 1
    end

    test "get_installation!/1 returns the installation with given id" do
      installation = installation_fixture()
      assert CustomerInstalls.get_installation!(installation.id).slug == installation.slug
      assert CustomerInstalls.get_installation!(installation.id).id == installation.id
    end

    test "get_installation!/2 returns the installation for a user" do
      user = insert(:user)
      installation = installation_fixture(user_id: user.id)

      assert CustomerInstalls.get_installation!(installation.id, user) == installation
    end

    test "get_installation!/2 returns the installation for a team" do
      team = insert(:team)
      installation = installation_fixture(team_id: team.id)

      assert CustomerInstalls.get_installation!(installation.id, team) == installation
    end

    test "create_installation/1 with valid data creates a installation" do
      valid_attrs = %{slug: "some-slug", kube_provider: :kind, usage: :development}

      assert {:ok, %Installation{} = installation} =
               CustomerInstalls.create_installation(valid_attrs)

      assert installation.slug == "some-slug"
    end

    test "create_installation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               CustomerInstalls.create_installation(@invalid_attrs)
    end

    test "update_installation/2 with valid data updates the installation" do
      installation = installation_fixture()
      update_attrs = %{slug: "some-updated-slug"}

      assert {:ok, %Installation{} = installation} =
               CustomerInstalls.update_installation(installation, update_attrs)

      assert installation.slug == "some-updated-slug"
    end

    test "update_installation/2 with invalid data returns error changeset" do
      installation = installation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               CustomerInstalls.update_installation(installation, @invalid_attrs)

      assert installation.id == CustomerInstalls.get_installation!(installation.id).id
    end

    test "delete_installation/1 soft deletes the record" do
      installation = installation_fixture()
      assert {:ok, %Installation{}} = CustomerInstalls.delete_installation(installation)

      assert_raise Ecto.NoResultsError, fn ->
        CustomerInstalls.get_installation!(installation.id)
      end

      # assert that there's still a record and that it's "soft" deleted
      all_installations = Repo.list_with_soft_deleted(Installation)
      assert length(all_installations) == 1

      found = List.first(all_installations)
      assert installation.slug == found.slug
      assert found.deleted_at != nil
    end

    test "soft deleted installations are still readable" do
      installation = installation_fixture()
      assert {:ok, %Installation{}} = CustomerInstalls.delete_installation(installation)

      # assert that there's still a record and that it's "soft" deleted
      all_installations = Repo.list_with_soft_deleted(Installation)
      assert length(all_installations) == 1

      found = List.first(all_installations)
      assert installation.id == found.id
      assert installation.slug == found.slug
    end

    test "change_installation/1 returns a installation changeset" do
      installation = installation_fixture()
      assert %Ecto.Changeset{} = CustomerInstalls.change_installation(installation)
    end
  end
end
