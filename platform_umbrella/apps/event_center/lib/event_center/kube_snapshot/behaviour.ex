defmodule EventCenter.KubeSnapshot.Behaviour do
  @moduledoc """
  Behaviour for EventCenter Kubernetes snapshot broadcasting. Defines callbacks for broadcasting Kubernetes state snapshots and subscribing to snapshot updates.
  """

  @doc """
  Broadcasts Kubernetes snapshot data to subscribers. Publishes current state snapshots of Kubernetes cluster resources and configuration.
  """
  @callback broadcast(snapshot :: any()) :: :ok | {:error, any()}

  @doc """
  Subscribes to Kubernetes snapshot events. Allows processes to receive notifications when new Kubernetes snapshots are available.
  """
  @callback subscribe() :: :ok | {:error, {:already_registered, pid()}}
end
