defmodule KubeServices.SnapshotApply.MissingKeycloakLauncher do
  @moduledoc false

  use GenServer
  use TypedStruct

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.KeycloakSummary
  alias KubeServices.SnapshotApply.Worker

  require Logger

  @state_opts ~w(delay initial_delay)a

  typedstruct module: State do
    field :delay, non_neg_integer(), default: 500
    field :initial_delay, non_neg_integer(), default: 15_000
    field :max_delay, non_neg_integer(), default: 60_000
    field :timer_reference, reference() | nil, default: nil
  end

  def start_link(opts \\ []) do
    {state_opts, server_opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, server_opts)
  end

  @impl GenServer
  @doc """
  Initialize the server by subscribing to EventCenter.KeycloakSnapshot
  """
  def init(args) do
    :ok = EventCenter.SystemStateSummary.subscribe()
    {:ok, struct(State, args)}
  end

  @impl GenServer

  def handle_info(:start_apply, state) do
    # should we handle the worker not starting?
    _ = Worker.start()
    {:noreply, %State{state | timer_reference: nil}}
  end

  def handle_info(%StateSummary{} = message, state) do
    keycloak_installed = CommonCore.StateSummary.Batteries.batteries_installed?(message, :keycloak)

    cond do
      # If the battery is installed but the state
      # is nil, we need to wait for keycloak to come
      # up. So keep scheduling a retry
      keycloak_installed && message.keycloak_state == nil ->
        Logger.info("Keycloak is installed but no snapshot yet. Scheduling next retry")
        {:noreply, schedule_start(state)}

      # If we're missing the batterycore realm, we need that.
      keycloak_installed && !KeycloakSummary.realm_member?(message.keycloak_state, "batterycore") ->
        Logger.info("Keycloak is installed but missing batterycore realm. Scheduling next retry")
        {:noreply, schedule_start(state)}

      keycloak_installed ->
        {:noreply, reset_delay(state)}

      !keycloak_installed ->
        {:noreply, state}
    end
  end

  defp schedule_start(%State{timer_reference: nil, max_delay: max_delay, delay: delay} = state) do
    new_delay = min(max_delay, delay * 2)
    Logger.debug("After missing keycloak snapshot or realm scheduling the next retry in #{new_delay}")

    %State{
      state
      | timer_reference: Process.send_after(self(), :start_apply, delay),
        delay: new_delay
    }
  end

  # handle case where snapshot fails while we're backing off
  defp schedule_start(%State{timer_reference: _} = state) do
    Logger.error("Missing keycloak snapshot timer already running. Ignoring")
    state
  end

  defp reset_delay(%State{initial_delay: init_delay, delay: delay} = state) when delay == init_delay, do: state

  defp reset_delay(%State{initial_delay: init_delay} = state) do
    Logger.debug("Successful apply, resetting delay back to initial values #{init_delay}")
    %State{state | delay: init_delay}
  end
end
