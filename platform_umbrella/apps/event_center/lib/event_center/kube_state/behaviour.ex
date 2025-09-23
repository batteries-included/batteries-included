defmodule EventCenter.KubeState.Behaviour do
  @moduledoc """
  Behaviour for EventCenter Kubernetes state broadcasting. Defines callbacks for broadcasting Kubernetes resource state changes and subscribing to resource events.
  """

  alias EventCenter.KubeState.Payload

  @doc """
  Broadcasts Kubernetes state change events to subscribers. Publishes resource state changes with action and resource data for specific resource types.
  """
  @callback broadcast(resource_type :: atom() | binary(), payload :: Payload.t()) :: :ok | {:error, any()}

  @doc """
  Broadcasts Kubernetes state change events with error raising. Similar to broadcast/2 but raises on errors instead of returning error tuples.
  """
  @callback broadcast!(resource_type :: atom() | binary(), payload :: Payload.t()) :: :ok

  @doc """
  Subscribes to Kubernetes state events for specified resource type. Allows processes to receive notifications of resource state changes.
  """
  @callback subscribe(resource_type :: atom() | binary()) :: :ok | {:error, any()}

  @doc """
  Unsubscribes to Kubernetes state events for specified resource type.
  """
  @callback unsubscribe(resource_type :: atom() | binary()) :: :ok | {:error, any()}
end
