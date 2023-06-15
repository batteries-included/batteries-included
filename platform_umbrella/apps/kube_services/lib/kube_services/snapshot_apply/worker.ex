defmodule KubeServices.SnapshotApply.Worker do
  use GenServer
  use TypedStruct

  alias KubeServices.SnapshotApply.KubeApply
  alias KubeServices.SnapshotApply.KeycloakApply
  alias KubeServices.SystemState.Summarizer
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias ControlServer.SnapshotApply.KeycloakSnapshot

  require Logger
  @me __MODULE__
  @state_opts [:running, :keycloak_running]

  typedstruct module: State do
    field :running, boolean(), default: true
    field :keycloak_running, boolean(), default: false
    field :init_delay, non_neg_integer(), default: 5_000
    field :delay, non_neg_integer(), default: 300_000
  end

  def start_link(opts \\ []) do
    {state_opts, opts} =
      opts
      |> Keyword.put_new(:name, @me)
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

  @doc """
  Handle the background message sent through `Process.send_after()` for periodic
  """
  def handle_info(:background, %State{delay: delay} = state) do
    {:ok, _} = do_start()
    Process.send_after(self(), :background, delay)
    {:noreply, state}
  end

  def handle_call(:start, _from, state) do
    {:reply, do_start(), state}
  end

  def handle_cast({:perform, umbrella_snapshot}, %State{running: true} = state) do
    :ok = do_perform(umbrella_snapshot, state)
    {:noreply, state}
  end

  def handle_cast({:perform, _umbrella_snapshot}, state) do
    {:noreply, state}
  end

  defp do_start do
    # Create the new umbrella snapshot.
    # If that works then schedule a cast immediately to
    case ControlServer.SnapshotApply.create_umbrella_snapshot(%{}) do
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
    # Prepare
    {:ok, kube_snap} = kube_prepare(umbrella_snapshot, state)
    {:ok, keycloak_snap} = keycloak_prepare(umbrella_snapshot, state)

    # Generation phase
    # Write everything to the database that we will be targeting
    # however as an optimization, we pass that data along to the
    # apply phase rather than re-fetching it from the db.
    summary = summary(state)
    {:ok, kube_gen_payload} = kube_generate(kube_snap, summary, state)
    {:ok, keycloak_gen_payload} = keycloak_generate(keycloak_snap, summary, state)

    # Apply phase.
    # Take the target database state and try applying it to the system.
    {:ok, _} = kube_apply(kube_snap, kube_gen_payload, state)
    {:ok, _} = keycloak_apply(keycloak_snap, keycloak_gen_payload, state)

    :ok
  end

  # Prepare
  defp kube_prepare(us, _state), do: KubeApply.prepare(us)
  defp keycloak_prepare(_us, %State{keycloak_running: false}), do: {:ok, nil}
  defp keycloak_prepare(us, %State{keycloak_running: true}), do: KeycloakApply.prepare(us)

  # Generate
  defp summary(_state), do: Summarizer.new()

  defp kube_generate(%KubeSnapshot{} = kube_snap, summary, _state),
    do: KubeApply.generate(kube_snap, summary)

  defp keycloak_generate(nil = _key_cloak_snapshot, _, _), do: {:ok, nil}
  defp keycloak_generate(%KeycloakSnapshot{} = _, _, _), do: {:ok, nil}

  # Apply
  defp kube_apply(kube_snap, gen_payload, _state), do: KubeApply.apply(kube_snap, gen_payload)
  defp keycloak_apply(nil = _kecloak_snap, _gen_payload, _state), do: {:ok, nil}
  defp keycloak_apply(%KeycloakSnapshot{} = _, _gen_payload, _state), do: {:ok, nil}
end
