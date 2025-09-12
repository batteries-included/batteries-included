defmodule EventCenter.Keycloak.Behaviour do
  @moduledoc """
  Behaviour for EventCenter Keycloak event broadcasting. Defines callbacks for broadcasting Keycloak API operations and subscribing to action topics.
  """

  alias EventCenter.Keycloak.Payload

  @doc """
  Broadcasts Keycloak operation events to subscribers. Publishes action payloads containing resource data from Keycloak API operations.
  """
  @callback broadcast(payload :: Payload.t()) :: :ok | {:error, term()}

  @doc """
  Broadcasts Keycloak operation events with error raising. Similar to broadcast/1 but raises on errors instead of returning error tuples.
  """
  @callback broadcast!(payload :: Payload.t()) :: :ok

  @doc """
  Subscribes to Keycloak action events on specified topic. Allows processes to receive notifications of Keycloak operations.
  """
  @callback subscribe(topic :: binary() | atom()) :: :ok | {:error, term()}
end
