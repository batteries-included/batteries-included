defmodule EventCenter.SystemStateSummary.Behaviour do
  @moduledoc """
  Behaviour for EventCenter system state summary broadcasting. Defines callbacks for broadcasting system state summaries and subscribing to summary updates.
  """

  @doc """
  Broadcasts system state summary data to subscribers. Publishes aggregated system state information and health summaries.
  """
  @callback broadcast(summary :: any()) :: :ok | {:error, any()}

  @doc """
  Subscribes to system state summary events. Allows processes to receive notifications when new system summaries are available.
  """
  @callback subscribe() :: :ok | {:error, any()}
end
