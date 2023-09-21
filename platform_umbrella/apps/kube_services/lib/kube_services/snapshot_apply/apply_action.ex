defmodule KubeServices.SnapshotApply.ApplyAction do
  @moduledoc false

  alias CommonCore.Keycloak.AdminClient
  alias ControlServer.ContentAddressable.Document
  alias ControlServer.SnapshotApply.KeycloakAction
  alias EventCenter.Keycloak.Payload

  require Logger

  @spec apply(ControlServer.SnapshotApply.KeycloakAction.t()) :: {:ok, any()} | {:error, any()}
  def apply(%KeycloakAction{action: :create, type: :realm} = action) do
    # Here we rely on the fact that
    # Document is already loaded for us
    case AdminClient.create_realm(action.document.value) do
      {:ok, realm_url} ->
        # Let everyone know that we did it and we are fun and cool
        :ok =
          EventCenter.Keycloak.broadcast(%Payload{
            action: :create_realm,
            resource: %{
              realm_url: realm_url,
              contents: action.document.value
            }
          })

        Logger.info("Created new realm #{realm_url}")
        {:ok, nil}

      {:error, err} ->
        Logger.warning("Error creating realm (will try again)  #{inspect(err)}")
        {:error, err}
    end
  end

  def apply(%KeycloakAction{action: :create, type: :client, realm: realm, document: %Document{value: value}}) do
    case AdminClient.create_client(realm, value) do
      {:ok, client_url} ->
        :ok =
          EventCenter.Keycloak.broadcast(%Payload{
            action: :create_client,
            resource: %{
              client_url: client_url,
              contents: value
            }
          })

        Logger.debug("Creating new client: #{value["id"]} for #{value["name"]}")
        {:ok, nil}

      {:error, :already_exists} ->
        Logger.info("Client already exists. This shouldn't typically happen")
        {:ok, nil}

      {:error, err} ->
        Logger.error("Error creating client: #{inspect(err)}")
        {:error, err}
    end
  end

  def apply(%KeycloakAction{} = _action), do: {:ok, nil}
end
