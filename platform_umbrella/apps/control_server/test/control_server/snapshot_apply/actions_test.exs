defmodule ControlServer.SnapshotApply.ActionsTest do
  use ControlServer.DataCase

  alias ControlServer.SnapshotApply.Actions

  describe "keycloak_actions" do
    import ControlServer.SnapshotApply.ActionsFixtures

    alias ControlServer.SnapshotApply.KeycloakAction

    @invalid_attrs %{
      action: :create,
      type: :user,
      post_handler: nil
    }

    test "list_keycloak_actions/0 returns all keycloak_actions" do
      keycloak_action = keycloak_action_fixture()
      assert Actions.list_keycloak_actions() == [keycloak_action]
    end

    test "get_keycloak_action!/1 returns the keycloak_action with given id" do
      keycloak_action = keycloak_action_fixture()
      assert Actions.get_keycloak_action!(keycloak_action.id) == keycloak_action
    end

    test "create_keycloak_action/1 with valid data creates a keycloak_action" do
      valid_attrs = %{
        action: :create,
        apply_result: "ok",
        type: :user,
        realm: "battery",
        post_handler: nil
      }

      assert {:ok, %KeycloakAction{} = keycloak_action} =
               Actions.create_keycloak_action(valid_attrs)

      assert keycloak_action.action == :create
      assert keycloak_action.apply_result == "ok"
    end

    test "create_keycloak_action/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Actions.create_keycloak_action(@invalid_attrs)
    end

    test "update_keycloak_action/2 with valid data updates the keycloak_action" do
      keycloak_action = keycloak_action_fixture()
      update_attrs = %{action: :sync, apply_result: "some updated result"}

      assert {:ok, %KeycloakAction{} = keycloak_action} =
               Actions.update_keycloak_action(keycloak_action, update_attrs)

      assert keycloak_action.action == :sync
      assert keycloak_action.apply_result == "some updated result"
    end

    test "update_keycloak_action/2 with invalid data returns error changeset" do
      keycloak_action = keycloak_action_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Actions.update_keycloak_action(keycloak_action, @invalid_attrs)

      assert keycloak_action == Actions.get_keycloak_action!(keycloak_action.id)
    end

    test "delete_keycloak_action/1 deletes the keycloak_action" do
      keycloak_action = keycloak_action_fixture()
      assert {:ok, %KeycloakAction{}} = Actions.delete_keycloak_action(keycloak_action)
      assert_raise Ecto.NoResultsError, fn -> Actions.get_keycloak_action!(keycloak_action.id) end
    end

    test "change_keycloak_action/1 returns a keycloak_action changeset" do
      keycloak_action = keycloak_action_fixture()
      assert %Ecto.Changeset{} = Actions.change_keycloak_action(keycloak_action)
    end
  end
end
