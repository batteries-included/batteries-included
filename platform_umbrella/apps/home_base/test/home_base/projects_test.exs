defmodule HomeBase.ProjectsTest do
  use HomeBase.DataCase

  import HomeBase.Factory

  alias CommonCore.Projects.ProjectSnapshot
  alias HomeBase.Projects

  setup do
    team = insert(:team)

    user_one = insert(:user)
    _team_role = insert(:team_role, team: team, user: user_one)

    user_two = insert(:user)

    install_zero = insert(:installation, team_id: team.id)
    install_one = insert(:installation, team_id: team.id)

    assert install_zero.team_id == team.id

    install_two = insert(:installation, user_id: user_two.id)
    install_three = insert(:installation, user_id: user_two.id)

    {:ok,
     team: team,
     user_one: user_one,
     user_two: user_two,
     install_zero: install_zero,
     install_one: install_one,
     install_two: install_two,
     install_three: install_three}
  end

  describe "snapshots for" do
    test "gets snapshots for same user", %{install_two: install_two, install_three: install_three} do
      {:ok, stored_snapshot} =
        Projects.create_stored_project_snapshot(%{
          installation_id: install_two.id,
          snapshot: %ProjectSnapshot{name: "snap", description: "test"}
        })

      possible_snaps = Projects.snapshots_for(install_three)

      assert [stored_snapshot.snapshot] == possible_snaps
    end

    test "gets snapshots for same team", %{install_zero: install_zero, install_one: install_one} do
      {:ok, stored_snapshot} =
        Projects.create_stored_project_snapshot(%{
          installation_id: install_zero.id,
          snapshot: %ProjectSnapshot{
            name: "snap",
            description: "test",
            redis_instances: []
          }
        })

      possible_snaps = Projects.snapshots_for(install_one)

      assert [stored_snapshot.snapshot] == possible_snaps
    end

    test "doesn't fail for un-owned installs" do
      install = insert(:installation)

      assert [] == Projects.snapshots_for(install)
    end
  end
end
