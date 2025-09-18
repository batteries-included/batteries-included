defmodule CommonCore.K8s.LeaderElection do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.ConnectionPool
  alias CommonCore.K8s.Client
  alias CommonCore.Resources.Builder, as: B
  alias K8s.Client.APIError

  require Logger

  typedstruct module: State do
    # Default timing configurations in milliseconds
    @default_lease_duration 15_000
    @default_renew_deadline 10_000
    @default_retry_period 2_000

    # The name of the ConfigMap used for leader election
    field :lock_name, String.t()
    # The namespace where the ConfigMap is located
    field :namespace, String.t()
    # Our unique identity for this instance
    field :identity, String.t()

    # Timing configurations in milliseconds
    field :lease_duration, integer()
    field :renew_deadline, integer()
    field :retry_period, integer()

    # Callback functions
    # These are user supplied functions that are called on leadership changes
    field :on_started_leading, (-> any()) | nil
    field :on_stopped_leading, (-> any()) | nil
    field :on_new_leader, (String.t() -> any()) | nil

    # The K8s connection and client
    field :conn, K8s.Conn.t() | nil
    field :conn_func, (-> K8s.Conn.t()) | nil

    # Internal state
    field :is_leader, boolean(), default: false
    field :observed_leader, String.t() | nil
    field :renew_timer_ref, reference() | nil
    field :acquire_timer_ref, reference() | nil
    field :kube_client, module(), default: Client

    @doc """
    Creates a new State struct from the given options.
    Returns {:ok, state} on success or {:error, reason} on validation failure.
    """
    def new!(opts) do
      struct!(__MODULE__,
        lock_name: Keyword.fetch!(opts, :lock_name),
        namespace: Keyword.fetch!(opts, :namespace),
        identity: Keyword.fetch!(opts, :identity),
        lease_duration: Keyword.get(opts, :lease_duration, @default_lease_duration),
        renew_deadline: Keyword.get(opts, :renew_deadline, @default_renew_deadline),
        retry_period: Keyword.get(opts, :retry_period, @default_retry_period),
        on_started_leading: Keyword.get(opts, :on_started_leading, nil),
        on_stopped_leading: Keyword.get(opts, :on_stopped_leading, nil),
        on_new_leader: Keyword.get(opts, :on_new_leader, nil),
        conn_func: Keyword.get(opts, :conn_func, nil),
        kube_client: Keyword.get(opts, :kube_client, Client)
      )
    end
  end

  @jitter_factor 1.2

  ## Public API

  @doc """
  Starts the leader election process.
  """
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    gen_opts = if name, do: [name: name], else: []
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  @doc """
  Returns true if this instance is currently the leader.
  """
  @spec leader?(GenServer.server()) :: boolean()
  def leader?(server) do
    GenServer.call(server, :is_leader)
  end

  @doc """
  Returns the identity of the current leader, or nil if unknown.
  """
  @spec get_leader(GenServer.server()) :: String.t() | nil
  def get_leader(server) do
    GenServer.call(server, :get_leader)
  end

  @doc """
  Manually release leadership (graceful shutdown).
  """
  @spec release_leadership(GenServer.server()) :: :ok
  def release_leadership(server) do
    GenServer.call(server, :release_leadership)
  end

  ## GenServer Callbacks

  @impl GenServer
  def init(opts) do
    {:ok, State.new!(opts), {:continue, :initialize}}
  end

  @impl GenServer
  def handle_continue(:initialize, %State{conn_func: conn_func} = state) when is_function(conn_func, 0) do
    # Start attempting to acquire leadership
    {:noreply, %{state | conn: conn_func.(), acquire_timer_ref: schedule_acquire_attempt(0)}}
  end

  @impl GenServer
  def handle_continue(:initialize, %State{conn_func: conn_func} = state) when is_nil(conn_func) do
    {:noreply, %{state | conn: ConnectionPool.get!(), acquire_timer_ref: schedule_acquire_attempt(0)}}
  end

  @impl GenServer
  def handle_call(:is_leader, _from, %State{is_leader: is_leader} = state) do
    {:reply, is_leader, state}
  end

  @impl GenServer
  def handle_call(:get_leader, _from, %State{observed_leader: observed_leader} = state) do
    {:reply, observed_leader, state}
  end

  @impl GenServer
  def handle_call(:release_leadership, _from, %State{is_leader: is_leader} = state) do
    with true <- is_leader,
         :ok <- release_lock(state) do
      # Happy path. We are out someone else can be leader now.
      {:reply, :ok, transition_to_follower(state)}
    else
      false ->
        {:reply, :ok, state}

      {:error, reason} ->
        # If there's an error releasing the lock, log it but still transition to follower
        Logger.warning("Failed to release leadership: #{inspect(reason)}")
        {:reply, {:error, reason}, transition_to_follower(state)}
    end
  end

  @impl GenServer
  def handle_info(:acquire_attempt, %State{} = state) do
    new_state = %{state | acquire_timer_ref: nil}

    case attempt_acquire_or_renew(new_state) do
      {:acquired, updated_state} ->
        # Became leader
        {:noreply,
         %{transition_to_leader(updated_state) | renew_timer_ref: schedule_renew_attempt(updated_state.renew_deadline)}}

      {:renewed, updated_state} ->
        # Already leader, renewed successfully
        {:noreply, %{updated_state | renew_timer_ref: schedule_renew_attempt(updated_state.renew_deadline)}}

      {:not_leader, %{is_leader: is_leader} = updated_state} ->
        # Someone else is leader, if that changes notify
        updated_state = if is_leader, do: transition_to_follower(updated_state), else: updated_state
        {:noreply, %{updated_state | acquire_timer_ref: schedule_acquire_attempt(updated_state.retry_period)}}

      {:error, reason} ->
        Logger.warning("Leader election error: #{inspect(reason)}")
        # On error, transition to follower and retry
        updated_state = if new_state.is_leader, do: transition_to_follower(new_state), else: new_state
        {:noreply, %{updated_state | acquire_timer_ref: schedule_acquire_attempt(updated_state.retry_period)}}
    end
  end

  @impl GenServer
  def handle_info(:renew_attempt, state) do
    new_state = %{state | renew_timer_ref: nil}

    case attempt_acquire_or_renew(new_state) do
      {:renewed, updated_state} ->
        # Successfully renewed
        timer_ref = schedule_renew_attempt(updated_state.renew_deadline)
        {:noreply, %{updated_state | renew_timer_ref: timer_ref}}

      {:acquired, updated_state} ->
        # Acquired leadership (lease expired during renew)
        updated_state = transition_to_leader(updated_state)
        timer_ref = schedule_renew_attempt(updated_state.renew_deadline)
        {:noreply, %{updated_state | renew_timer_ref: timer_ref}}

      {:not_leader, updated_state} ->
        # Lost leadership
        updated_state = transition_to_follower(updated_state)
        timer_ref = schedule_acquire_attempt(updated_state.retry_period)
        {:noreply, %{updated_state | acquire_timer_ref: timer_ref}}

      {:error, reason} ->
        Logger.warning("Leader renewal error: #{inspect(reason)}")
        # On error, assume lost leadership and try to re-acquire
        updated_state = transition_to_follower(new_state)
        timer_ref = schedule_acquire_attempt(updated_state.retry_period)
        {:noreply, %{updated_state | acquire_timer_ref: timer_ref}}
    end
  end

  @impl GenServer
  def terminate(
        _reason,
        %State{renew_timer_ref: renew_timer_ref, acquire_timer_ref: acquire_timer_ref, is_leader: is_leader} = state
      ) do
    # Clean up timers
    _ = if renew_timer_ref, do: _ = Process.cancel_timer(renew_timer_ref)
    _ = if acquire_timer_ref, do: _ = Process.cancel_timer(acquire_timer_ref)

    # Try to release leadership gracefully
    _ = if is_leader, do: release_lock(state)

    :ok
  end

  ## Private Functions

  defp attempt_acquire_or_renew(%State{lease_duration: lease_duration, identity: identity} = state) do
    case get_leader_record(state) do
      {:ok, current_record} ->
        now = System.system_time(:millisecond)

        case current_record do
          nil ->
            # No existing record, try to create one
            create_leader_record(state, now)

          record ->
            # Check if current leader's lease has expired
            lease_expires_at = record["renewTime"] + lease_duration

            cond do
              # We are the current leader - try to renew
              record["holderIdentity"] == identity and now < lease_expires_at ->
                renew_leader_record(state, record, now)

              # Current lease has expired - try to acquire
              now >= lease_expires_at ->
                acquire_leader_record(state, record, now)

              # Someone else is leader and lease is valid
              true ->
                new_observed_leader = record["holderIdentity"]
                updated_state = maybe_report_new_leader(state, new_observed_leader)
                {:not_leader, updated_state}
            end
        end

      error ->
        error
    end
  end

  defp get_leader_record(%State{kube_client: kube_client, namespace: namespace, lock_name: lock_name, conn: conn}) do
    operation =
      kube_client.get("v1", "ConfigMap",
        namespace: namespace,
        name: lock_name
      )

    case kube_client.run(conn, operation) do
      {:ok, configmap} ->
        annotations = get_in(configmap, ["metadata", "annotations"]) || %{}
        leader_data = annotations["battery.election/leader"]

        case leader_data do
          nil ->
            {:ok, nil}

          data ->
            case Jason.decode(data) do
              {:ok, record} -> {:ok, record}
              {:error, _} -> {:ok, nil}
            end
        end

      {:error, %APIError{reason: "NotFound"}} ->
        {:ok, nil}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp create_leader_record(%State{kube_client: kube_client, conn: conn, identity: identity} = state, now) do
    record = build_leader_record(state, now, now, 0)

    configmap = build_config_map(state, record)

    operation = kube_client.create(configmap)

    case kube_client.run(conn, operation) do
      {:ok, _} ->
        updated_state = %{state | observed_leader: identity}
        {:acquired, updated_state}

      {:error, %APIError{reason: "AlreadyExists"}} ->
        # Someone else created it first, try again
        attempt_acquire_or_renew(state)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp renew_leader_record(state, current_record, now) do
    acquire_time = current_record["acquireTime"]
    leader_transitions = current_record["leaderTransitions"] || 0

    updated_record = build_leader_record(state, acquire_time, now, leader_transitions)
    update_leader_record(state, updated_record, :renewed)
  end

  defp acquire_leader_record(state, current_record, now) do
    leader_transitions = (current_record["leaderTransitions"] || 0) + 1

    updated_record = build_leader_record(state, now, now, leader_transitions)
    update_leader_record(state, updated_record, :acquired)
  end

  defp update_leader_record(%State{kube_client: kube_client, conn: conn, identity: identity} = state, record, result_type) do
    configmap = build_config_map(state, record)

    operation = kube_client.apply(configmap)

    case kube_client.run(conn, operation) do
      {:ok, _} ->
        updated_state = %{state | observed_leader: identity}
        {result_type, updated_state}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_leader_record(
         %State{identity: identity, lease_duration: lease_duration},
         acquire_time,
         renew_time,
         leader_transitions
       ) do
    %{
      "holderIdentity" => identity,
      "leaseDurationSeconds" => div(lease_duration, 1000),
      "acquireTime" => acquire_time,
      "renewTime" => renew_time,
      "leaderTransitions" => leader_transitions
    }
  end

  defp build_config_map(%State{lock_name: lock_name, namespace: namespace}, record) do
    :config_map
    |> B.build_resource()
    |> B.name(lock_name)
    |> B.namespace(namespace)
    |> B.managed_indirect_labels()
    |> B.annotation("battery.election/leader", Jason.encode!(record))
  end

  defp release_lock(%State{kube_client: kube_client, conn: conn} = state) do
    # Set lease duration to 1 second to effectively release it
    record = %{
      "holderIdentity" => "",
      "leaseDurationSeconds" => 1,
      "acquireTime" => System.system_time(:millisecond),
      "renewTime" => System.system_time(:millisecond),
      "leaderTransitions" => 0
    }

    configmap = build_config_map(state, record)

    operation = kube_client.apply(configmap)

    case kube_client.run(conn, operation) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Logger.warning("Failed to release leadership lock: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp transition_to_leader(
         %State{identity: identity, acquire_timer_ref: acquire_timer_ref, on_started_leading: on_started_leading} = state
       ) do
    Logger.info("Became leader: #{identity}")

    # Cancel any pending acquire timer
    _ = if acquire_timer_ref, do: Process.cancel_timer(acquire_timer_ref)

    # Call the callback if provided
    _ = if on_started_leading, do: spawn(fn -> on_started_leading.() end)

    %{state | is_leader: true, acquire_timer_ref: nil, observed_leader: identity}
  end

  defp transition_to_follower(
         %State{
           is_leader: is_leader,
           identity: identity,
           on_stopped_leading: on_stopped_leading,
           renew_timer_ref: renew_timer_ref
         } = state
       ) do
    _ =
      if is_leader do
        Logger.info("Lost leadership: #{identity}")

        # Call the callback if provided
        _ = if on_stopped_leading, do: spawn(fn -> on_stopped_leading.() end)
      end

    # Cancel any pending renew timer
    _ = if renew_timer_ref, do: Process.cancel_timer(renew_timer_ref)

    %{state | is_leader: false, renew_timer_ref: nil}
  end

  defp maybe_report_new_leader(%State{observed_leader: observed_leader, on_new_leader: on_new_leader} = state, new_leader) do
    if observed_leader == new_leader do
      state
    else
      Logger.info("Observed new leader: #{new_leader}")

      # Call the callback if provided
      _ = if on_new_leader, do: spawn(fn -> on_new_leader.(new_leader) end)

      %{state | observed_leader: new_leader}
    end
  end

  defp schedule_acquire_attempt(delay) do
    jittered_delay = add_jitter(delay)
    Process.send_after(self(), :acquire_attempt, jittered_delay)
  end

  defp schedule_renew_attempt(delay) do
    jittered_delay = add_jitter(delay)
    Process.send_after(self(), :renew_attempt, jittered_delay)
  end

  defp add_jitter(delay) do
    jitter = trunc(delay * (@jitter_factor - 1.0) * :rand.uniform())
    delay + jitter
  end
end
