defmodule KubeServices.SnapshotApply.ApplyAction do
  @moduledoc false
  alias CommonCore.Keycloak.AdminClient
  alias ControlServer.SnapshotApply.KeycloakAction

  require Logger

  @spec apply(ControlServer.SnapshotApply.KeycloakAction.t()) :: {:ok, any()} | {:error, any()}
  def apply(%KeycloakAction{action: :create, type: :realm} = action) do
    # Here we rely on the fact that
    # Document is already loaded for us
    case AdminClient.create_realm(action.document.value) do
      {:ok, realm_url} ->
        # Let everyone know that we did it and we are fun and cool
        :ok = EventCenter.Keycloak.broadcast(:create_realm, %{realm_url: realm_url, contents: action.document.value})
        Logger.info("Created new realm #{realm_url}")
        {:ok, nil}

      {:error, err} ->
        Logger.warning("Error creating realm (will try again)  #{inspect(err)}")
        {:error, err}
    end
  end

  def apply(%KeycloakAction{} = _action) do
    {:ok, nil}
  end
end
