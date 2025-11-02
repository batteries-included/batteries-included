defmodule EventCenter.KeycloakSnapshot.Behaviour do
  @moduledoc """
  Behaviour for EventCenter Keycloak snapshot broadcasting. Defines callbacks for broadcasting Keycloak state snapshots and subscribing to snapshot updates.
  """

  @doc """
  Broadcasts Keycloak snapshot data to subscribers. Publishes current state snapshots of Keycloak configuration and resources.
  """
  @callback broadcast(snapshot :: any()) :: :ok | {:error, any()}

  @doc """
  Subscribes to Keycloak snapshot events. Allows processes to receive notifications when new Keycloak snapshots are available.
  """
  @callback subscribe() :: :ok | {:error, {:already_registered, pid()}}
end
