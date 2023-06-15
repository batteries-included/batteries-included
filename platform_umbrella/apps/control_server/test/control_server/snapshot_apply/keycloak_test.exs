defmodule ControlServer.SnapshotApply.KeycloakTest do
  use ControlServer.DataCase

  alias ControlServer.SnapshotApply.Keycloak

  describe "keycloak_snapshots" do
    alias ControlServer.SnapshotApply.KeycloakSnapshot

    import ControlServer.KeycloakSnapshotApplyFixtures

    @invalid_attrs %{status: nil}

    test "list_keycloak_snapshots/0 returns all keycloak_snapshots" do
      keycloak_snapshot = keycloak_snapshot_fixture()
      assert Keycloak.list_keycloak_snapshots() == [keycloak_snapshot]
    end

    test "get_keycloak_snapshot!/1 returns the keycloak_snapshot with given id" do
      keycloak_snapshot = keycloak_snapshot_fixture()

      assert Keycloak.get_keycloak_snapshot!(keycloak_snapshot.id) ==
               keycloak_snapshot
    end

    test "create_keycloak_snapshot/1 with valid data creates a keycloak_snapshot" do
      valid_attrs = %{status: :creation}

      assert {:ok, %KeycloakSnapshot{} = keycloak_snapshot} =
               Keycloak.create_keycloak_snapshot(valid_attrs)

      assert keycloak_snapshot.status == :creation
    end

    test "create_keycloak_snapshot/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Keycloak.create_keycloak_snapshot(@invalid_attrs)
    end

    test "update_keycloak_snapshot/2 with valid data updates the keycloak_snapshot" do
      keycloak_snapshot = keycloak_snapshot_fixture()
      update_attrs = %{status: :generation}

      assert {:ok, %KeycloakSnapshot{} = keycloak_snapshot} =
               Keycloak.update_keycloak_snapshot(keycloak_snapshot, update_attrs)

      assert keycloak_snapshot.status == :generation
    end

    test "update_keycloak_snapshot/2 with invalid data returns error changeset" do
      keycloak_snapshot = keycloak_snapshot_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Keycloak.update_keycloak_snapshot(keycloak_snapshot, @invalid_attrs)

      assert keycloak_snapshot ==
               Keycloak.get_keycloak_snapshot!(keycloak_snapshot.id)
    end

    test "delete_keycloak_snapshot/1 deletes the keycloak_snapshot" do
      keycloak_snapshot = keycloak_snapshot_fixture()

      assert {:ok, %KeycloakSnapshot{}} = Keycloak.delete_keycloak_snapshot(keycloak_snapshot)

      assert_raise Ecto.NoResultsError, fn ->
        Keycloak.get_keycloak_snapshot!(keycloak_snapshot.id)
      end
    end

    test "change_keycloak_snapshot/1 returns a keycloak_snapshot changeset" do
      keycloak_snapshot = keycloak_snapshot_fixture()
      assert %Ecto.Changeset{} = Keycloak.change_keycloak_snapshot(keycloak_snapshot)
    end
  end
end
