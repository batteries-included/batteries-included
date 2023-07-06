defmodule ControlServer.SnapshotApply.KeycloakEctoSteps do
  alias ControlServer.SnapshotApply.KeycloakSnapshot
  import ControlServer.SnapshotApply.Keycloak

  def create_snap(attrs \\ %{}) do
    create_keycloak_snapshot(attrs)
  end

  def snap_generation(%KeycloakSnapshot{} = _snap, _), do: {:ok, nil}
end
