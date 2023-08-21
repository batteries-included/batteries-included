defmodule KubeServices.SnapshotApply.ApplyAction do
  @moduledoc false
  alias CommonCore.Keycloak.AdminClient
  alias ControlServer.SnapshotApply.KeycloakAction

  @spec apply(ControlServer.SnapshotApply.KeycloakAction.t()) :: {:ok, nil}
  def apply(%KeycloakAction{action: :create, type: :realm} = action) do
    # Here we rely on the fact that
    # Document is already loaded for us
    case AdminClient.create_realm(action.document.value) do
      {:ok, _new_url} ->
        {:ok, nil}

      err ->
        {:error, err}
    end
  end

  def apply(%KeycloakAction{} = _action) do
    {:ok, nil}
  end
end
