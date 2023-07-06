defmodule ControlServer.SnapshotApply.ActionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.SnapshotApply.Actions` context.
  """

  @doc """
  Generate a keycloak_action.
  """
  def keycloak_action_fixture(attrs \\ %{}) do
    {:ok, keycloak_action} =
      attrs
      |> Enum.into(%{
        action: :create,
        result: "ok",
        type: :realm,
        post_handler: nil
      })
      |> ControlServer.SnapshotApply.Actions.create_keycloak_action()

    keycloak_action
  end
end
