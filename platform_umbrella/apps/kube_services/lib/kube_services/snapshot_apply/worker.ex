defmodule KubeServices.SnapshotApply.Worker do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias ControlServer.Batteries
  alias ControlServer.SnapshotApply.KeycloakSnapshot
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias ControlServer.SnapshotApply.Umbrella
  alias KubeServices.SnapshotApply.KeycloakApply
  alias KubeServices.SnapshotApply.KubeApply
  alias KubeServices.SystemState.Summarizer

  require Logger

  @me __MODULE__
  @state_opts [:running, :init_delay, :delay]

  typedstruct module: State do
    field :running, boolean(), default: true
    field :init_delay, non_neg_integer(), default: 5_000
    field :delay, non_neg_integer(), default: 300_000
    field :last_success, DateTime.t(), default: nil
  end

  def start_link(opts \\ []) do
    {state_opts, opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.put_new(:keycloak_enabled, Batteries.battery_enabled?(:keycloak))
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  def init(opts) do
    state = struct(State, opts)
    Process.send_after(self(), :background, state.init_delay)
    {:ok, state}
  end

  def start(target \\ @me) do
    GenServer.call(target, :start)
  end

  @spec set_running(atom() | pid() | {atom(), any()} | {:via, atom(), any()}, boolean()) :: boolean()
  def set_running(target \\ @me, value) do
    GenServer.call(target, {:set_running, value})
  end

  @spec get_running(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) :: boolean()
  def get_running(target \\ @me) do
    # The Worker might not be running because it crashed.
    # We want that to mean it's not running
    GenServer.call(target, :get_running)
  rescue
    _ -> false
  catch
    _ -> false
    _e, _r -> false
  end

  @spec get_last_success(atom() | pid() | {atom(), any()} | {:via, atom(), any()}) ::
          {:ok, DateTime.t() | nil} | {:error, String.t()}
  def get_last_success(target \\ @me) do
    last = GenServer.call(target, :get_last_success)
    {:ok, last}
  rescue
    _ -> {:error, "Can't get last success"}
  catch
    _ -> {:error, "Can't get last success"}
    _, _ -> {:error, "Can't get last success"}
  end

  @doc """
  Handle the background message sent through `Process.send_after()` for periodic
  """
  def handle_info(:background, %State{delay: delay, running: running} = state) do
    {:ok, _} = do_start(running)
    Process.send_after(self(), :background, delay)
    {:noreply, state}
  end

  def handle_call(:start, _from, %State{running: running} = state) do
    {:reply, do_start(running), state}
  end

  def handle_call(:get_running, _from, %State{running: was_running} = state) do
    {:reply, was_running, state}
  end

  def handle_call(:get_last_success, _from, %State{last_success: last_success} = state) do
    {:reply, last_success, state}
  end

  def handle_call({:set_running, running}, _from, %State{running: was_running} = state) do
    {:reply, was_running, %{state | running: running}}
  end

  def handle_cast({:perform, umbrella_snapshot}, %State{} = state) do
    :ok = do_perform(umbrella_snapshot, state)
    {:noreply, %{state | last_success: DateTime.utc_now()}}
  end

  defp do_start(false), do: {:ok, nil}

  defp do_start(true = _running) do
    # Create the new umbrella snapshot.
    # If that works then schedule a cast immediately to perform snapshot
    case Umbrella.create_umbrella_snapshot(%{}) do
      {:ok, umbrella_snapshot} ->
        GenServer.cast(self(), {:perform, umbrella_snapshot})
        {:ok, umbrella_snapshot}

      {:error, _changeset} ->
        {:error, :bad_ecto}

      err ->
        {:error, err}
    end
  end

  defp do_perform(umbrella_snapshot, state) do
    summary = summary(state)

    # Prepare
    {:ok, kube_snap} = kube_prepare(umbrella_snapshot, summary)
    {:ok, keycloak_snap} = keycloak_prepare(umbrella_snapshot, summary)

    # Generation phase
    # Write everything to the database that we will be targeting
    # however as an optimization, we pass that data along to the
    # apply phase rather than re-fetching it from the db.
    {:ok, kube_gen_payload} = kube_generate(kube_snap, summary)
    {:ok, keycloak_gen_payload} = keycloak_generate(keycloak_snap, summary)

    # Apply phase.
    # Take the target database state and try applying it to the system.
    {:ok, _} = kube_apply(kube_snap, kube_gen_payload)
    {:ok, _} = keycloak_apply(keycloak_snap, keycloak_gen_payload)

    :ok
  end

  # Prepare
  defp kube_prepare(us, _summary), do: KubeApply.prepare(us)

  defp keycloak_prepare(us, summary) do
    if CommonCore.StateSummary.Batteries.batteries_installed?(summary, :keycloak) do
      KeycloakApply.prepare(us)
    else
      {:ok, nil}
    end
  end

  # Generate
  defp summary(_state), do: Summarizer.new()

  defp kube_generate(%KubeSnapshot{} = kube_snap, summary), do: KubeApply.generate(kube_snap, summary)

  defp keycloak_generate(nil = _key_cloak_snapshot, _), do: {:ok, nil}
  defp keycloak_generate(%KeycloakSnapshot{} = key_snap, summary), do: KeycloakApply.generate(key_snap, summary)

  # Apply
  defp kube_apply(kube_snap, gen_payload), do: KubeApply.apply(kube_snap, gen_payload)
  defp keycloak_apply(nil = _keycloak_snap, _gen_payload), do: {:ok, nil}
  defp keycloak_apply(%KeycloakSnapshot{} = key_snap, actions), do: KeycloakApply.apply(key_snap, actions)
end
