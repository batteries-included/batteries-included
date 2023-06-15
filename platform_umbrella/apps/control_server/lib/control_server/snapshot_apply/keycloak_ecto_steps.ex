defmodule ControlServer.SnapshotApply.KeycloakEctoSteps do
  import ControlServer.SnapshotApply.Keycloak

  def create_snap(attrs \\ %{}) do
    create_keycloak_snapshot(attrs)
  end
end
