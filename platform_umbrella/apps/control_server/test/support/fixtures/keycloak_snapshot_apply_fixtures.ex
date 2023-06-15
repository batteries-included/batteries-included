defmodule ControlServer.KeycloakSnapshotApplyFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ControlServer.KeycloakSnapshotApply` context.
  """

  @doc """
  Generate a keycloak_snapshot.
  """
  def keycloak_snapshot_fixture(attrs \\ %{}) do
    {:ok, keycloak_snapshot} =
      attrs
      |> Enum.into(%{
        status: :creation
      })
      |> ControlServer.SnapshotApply.Keycloak.create_keycloak_snapshot()

    keycloak_snapshot
  end
end
