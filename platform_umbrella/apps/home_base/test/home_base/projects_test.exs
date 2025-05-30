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
    test "gets snapshot list for same user", %{install_two: install_two, install_three: install_three} do
      {:ok, stored_snapshot} =
        Projects.create_stored_project_snapshot(%{
          installation_id: install_two.id,
          snapshot: %ProjectSnapshot{name: "snap", description: "test"}
        })

      possible_snaps = Projects.snapshots_for(install_three)

      expected = %{
        id: stored_snapshot.id,
        name: stored_snapshot.snapshot.name,
        description: stored_snapshot.snapshot.description,
        num_postgres_clusters: 0,
        num_redis_instances: 0,
        num_jupyter_notebooks: 0,
        num_knative_services: 0,
        num_traditional_services: 0,
        num_model_instances: 0
      }

      assert [expected] == possible_snaps
      assert stored_snapshot.installation_id == install_two.id
    end

    test "gets snapshot list for same team", %{install_zero: install_zero, install_one: install_one} do
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

      expected = %{
        id: stored_snapshot.id,
        name: stored_snapshot.snapshot.name,
        description: stored_snapshot.snapshot.description,
        num_postgres_clusters: 0,
        num_redis_instances: 0,
        num_jupyter_notebooks: 0,
        num_knative_services: 0,
        num_traditional_services: 0,
        num_model_instances: 0
      }

      assert [expected] == possible_snaps
    end

    test "doesn't fail for un-owned installs" do
      install = insert(:installation)

      assert [] == Projects.snapshots_for(install)
    end

    test "gets public snapshots from other installations",
         %{install_zero: install_zero, install_two: install_two} do
      {:ok, stored_snapshot} =
        Projects.create_stored_project_snapshot(%{
          installation_id: install_zero.id,
          snapshot: %ProjectSnapshot{name: "snap", description: "test"},
          visibility: :public
        })

      # This should be not visible to install_two
      {:ok, _stored_snapshot_two} =
        Projects.create_stored_project_snapshot(%{
          installation_id: install_zero.id,
          snapshot: %ProjectSnapshot{name: "snap2", description: "test2"},
          visibility: :private
        })

      possible_snaps = Projects.snapshots_for(install_two)

      expected = %{
        id: stored_snapshot.id,
        name: stored_snapshot.snapshot.name,
        description: stored_snapshot.snapshot.description,
        num_postgres_clusters: 0,
        num_redis_instances: 0,
        num_jupyter_notebooks: 0,
        num_knative_services: 0,
        num_traditional_services: 0,
        num_model_instances: 0
      }

      assert [expected] == possible_snaps
    end
  end
end
