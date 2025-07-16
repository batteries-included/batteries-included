defmodule KubeServices.SnapshotApply.KeycloakApply do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.Actions.RootActionGenerator
  alias CommonCore.StateSummary
  alias ControlServer.SnapshotApply.KeycloakAction
  alias ControlServer.SnapshotApply.KeycloakEctoSteps
  alias ControlServer.SnapshotApply.KeycloakSnapshot
  alias ControlServer.SnapshotApply.UmbrellaSnapshot
  alias KubeServices.SnapshotApply.ApplyAction

  require Logger

  @me __MODULE__
  @state_opts []

  typedstruct module: State do
  end

  @spec start_link(keyword()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(opts \\ []) do
    {state_opts, opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  @impl GenServer
  @spec init(keyword()) :: {:ok, State.t()}
  def init(opts \\ []) do
    {:ok, struct(State, opts)}
  end

  ##
  # These are the public functions that will be
  # called by KubeServices.SnapshotApply.Worker
  #
  # They generally follow the prepare, generate, apply stages of SnapshotApply
  ##

  @spec prepare(UmbrellaSnapshot.t()) :: any
  def prepare(%UmbrellaSnapshot{id: id} = _us) do
    args = %{umbrella_snapshot_id: id, status: :creation}
    KeycloakEctoSteps.create_snap(args)
  end

  @spec generate(KeycloakSnapshot.t(), StateSummary.t()) :: any
  def generate(snap, summary) do
    GenServer.call(@me, {:generate, snap, summary}, 600_000)
  end

  @spec apply(KeycloakSnapshot.t(), list(KeycloakAction.t())) :: any
  def apply(snap, actions) do
    GenServer.call(@me, {:apply, snap, actions}, 600_000)
  end

  def get_running(target \\ @me) do
    # the worker might not be started yet
    GenServer.call(target, :get_running)
  rescue
    _ -> false
  catch
    _ -> false
    _e, _r -> false
  end

  @impl GenServer
  def handle_call(:get_running, _from, state) do
    {:reply, true, state}
  end

  @impl GenServer
  def handle_call({:generate, snap, summary}, _from, state) do
    {:reply, do_generate(snap, summary, state), state}
  end

  @impl GenServer
  def handle_call({:apply, snap, actions}, _from, state) do
    {:reply, do_apply(snap, actions, state), state}
  end

  defp do_generate(%KeycloakSnapshot{} = snap, %StateSummary{} = summary, _state) do
    # Set the snapshot to generating
    with {:ok, up_g_snap} <- KeycloakEctoSteps.update_snap_status(snap, :generation),
         # Create the base actions
         base_actions = RootActionGenerator.materialize(summary),
         # Store the json in CAS and use that to create Actions
         {:ok, %{actions: actions}} <- KeycloakEctoSteps.snap_generation(up_g_snap, base_actions) do
      # Return the actions
      {:ok, actions}
    end
  end

  defp do_apply(%KeycloakSnapshot{} = snap, actions, %State{} = _state) do
    # Record that we're going to start applying
    with {:ok, up_g_snap} <- KeycloakEctoSteps.update_snap_status(snap, :applying),
         # Apply the actions
         {:ok, apply_result} <- apply_actions(actions) do
      # The results for the keycloak snapshot need
      # to be written after all the actions have been accounted for.
      final_snap_update(up_g_snap, apply_result)
    end
  end

  @spec apply_actions(list(KeycloakAction.t())) :: {:ok, any()} | {:error, any()}
  defp apply_actions(actions) do
    updates =
      Enum.map(actions, fn action ->
        # This sends the actual action to
        # Keycloak.
        case ApplyAction.apply(action) do
          # After applying plan what we need to change with
          # an update to each action.
          {:ok, _good_result} ->
            %{is_success: true, apply_result: nil}

          {:error, bad_result} ->
            %{is_success: false, apply_result: reason_string(bad_result)}
        end
      end)

    # Tell the database about what happened in all the actions, batch style.
    KeycloakEctoSteps.update_actions(actions, updates)
  end

  defp final_snap_update(snap, apply_results) do
    status =
      if Enum.all?(apply_results, fn {_, action} -> action.is_success end) do
        :ok
      else
        :error
      end

    KeycloakEctoSteps.update_snap_status(snap, status)
  end

  defp reason_string(nil), do: nil
  defp reason_string(reason_atom) when is_atom(reason_atom), do: Atom.to_string(reason_atom)
  defp reason_string(reason) when is_binary(reason), do: reason
  defp reason_string(obj), do: inspect(obj)
end
