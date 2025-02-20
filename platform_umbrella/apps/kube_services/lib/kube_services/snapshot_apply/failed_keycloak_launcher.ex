defmodule KubeServices.SnapshotApply.FailedKeycloakLauncher do
  @moduledoc """
  This GenServer handles failed keycloak snapshots.

  It does this by subscribing to `EventCenter.KeycloakSnapshot` and starting
  `KubeServices.SnapshotApply.Worker` on snapshot failures.

  It should handle back off by exponentially delaying on subsequent failures
  and resetting on success.
  """
  use GenServer
  use TypedStruct

  alias ControlServer.SnapshotApply.KeycloakSnapshot
  alias EventCenter.KeycloakSnapshot.Payload
  alias KubeServices.SnapshotApply.Worker

  require Logger

  typedstruct module: State do
    field :delay, non_neg_integer(), default: 5000
    field :initial_delay, non_neg_integer(), default: 5000
    field :max_delay, non_neg_integer(), default: 600_000
    field :timer_reference, reference() | nil, default: nil
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  @doc """
  Initialize the server by subscribing to EventCenter.KeycloakSnapshot
  """
  def init(args) do
    :ok = EventCenter.KeycloakSnapshot.subscribe()
    {:ok, struct(State, args)}
  end

  @impl GenServer
  @doc """
  Handle regular messages
  """
  # start a `KubeServices.SnapshotApply.Worker` and remove the reference to the
  # timer that invoked this message
  def handle_info(:start_apply, state) do
    # should we handle the worker not starting?
    _ = Worker.start()
    {:noreply, %{state | timer_reference: nil}}
  end

  # kick off the loop when there's a snapshot error
  def handle_info(%Payload{snapshot: %KeycloakSnapshot{status: :error}} = _payload, state) do
    {:noreply, schedule_start(state)}
  end

  # reset the backoff when there's a successful snapshot
  def handle_info(%Payload{snapshot: %KeycloakSnapshot{status: :ok}} = _payload, state) do
    {:noreply, reset_delay(state)}
  end

  # ignore in progress snapshot apply
  def handle_info(%Payload{snapshot: _} = _payload, state) do
    {:noreply, state}
  end

  # start loop after delay based on current state
  defp schedule_start(%State{timer_reference: nil, max_delay: max_delay, delay: delay} = state) do
    new_delay = min(max_delay, delay * 2)
    Logger.warning("After a failed snapshot scheduling the next retry in #{new_delay}")

    %{
      state
      | timer_reference: Process.send_after(self(), :start_apply, delay),
        delay: new_delay
    }
  end

  # handle case where snapshot fails while we're backing off
  defp schedule_start(%State{timer_reference: _} = state) do
    Logger.info("Failed snapshot timer already running. Ignoring")
    state
  end

  # reset delay in state to the initial delay
  defp reset_delay(%State{initial_delay: init_delay, delay: delay} = state) when delay == init_delay, do: state

  defp reset_delay(%State{initial_delay: init_delay} = state) do
    Logger.debug("Successful apply, resetting delay back to initial values #{init_delay}")
    %{state | delay: init_delay}
  end
end
