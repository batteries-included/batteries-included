defmodule ControlServer.SnapshotApply.KeycloakEctoStepsTest do
  use ControlServer.DataCase

  import CommonCore.Factory

  alias CommonCore.Actions.RootActionGenerator
  alias ControlServer.KeycloakSnapshotApplyFixtures
  alias ControlServer.SnapshotApply.Actions
  alias ControlServer.SnapshotApply.KeycloakEctoSteps

  setup do
    %{
      snap: KeycloakSnapshotApplyFixtures.keycloak_snapshot_fixture(),
      summary: build(:install_spec, usage: :kitchen_sink, kube_provider: :aws).target_summary
    }
  end

  describe "keycloak ecto steps" do
    test "can generate actions and are stored to database", %{snap: snap, summary: summary} do
      base_actions = RootActionGenerator.materialize(summary)
      {:ok, %{actions: actions}} = KeycloakEctoSteps.snap_generation(snap, base_actions)

      # ensure that they were actually stored in the db
      Enum.each(actions, &Actions.get_keycloak_action!(&1.id))
    end
  end
end
