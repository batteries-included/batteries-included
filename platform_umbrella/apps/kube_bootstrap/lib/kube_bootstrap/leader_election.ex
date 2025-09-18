defmodule KubeBootstrap.LeaderElection do
  @moduledoc false
  use GenServer
  use TypedStruct

  import CommonCore.Util.Map

  alias CommonCore.Resources.Builder, as: B
  alias K8s.Client.APIError

  require Logger

  @lease_duration 15
  @renew_deadline 10
  # @retry_period 2

  typedstruct module: State do
    field(:tasks, :map)
    field(:supervisor, :atom)
  end

  @state_opts ~w(supervisor)a

  def start_link(opts \\ []) do
    {state_opts, gen_opts} =
      opts
      |> Keyword.put_new(:name, __MODULE__)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, gen_opts)
  end

  @impl GenServer
  def init(args) do
    state = struct!(State, args)

    Logger.info("Starting LeaderElection")
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:run, conn, args}, from, state) do
    now = DateTime.utc_now()

    case acquire(conn, now, args) do
      :error ->
        {:reply, :error, state}

      :ok ->
        renew_deadline = Keyword.get(args, :renew_deadline, @renew_deadline)
        {:noreply, state, {:continue, {:run, conn, renew_deadline * 1000, args, from}}}
    end
  end

  @impl GenServer
  def handle_continue({:run, conn, timeout, args, from}, state) do
    cb = Keyword.fetch!(args, :run_callback)
    task = Task.Supervisor.async_nolink(state.supervisor, cb)
    Process.send_after(self(), {:renew, task}, timeout)
    tasks = Map.put(state.tasks, task.ref, {conn, args, from})
    {:noreply, struct!(state, tasks: tasks)}
  end

  @impl GenServer
  def handle_info({:renew, task}, %{tasks: tasks} = state) do
    {conn, args, from} = tasks[task]
    now = DateTime.utc_now()

    case acquire(conn, now, args) do
      :error ->
        Logger.error("failed to acquire/renew lease. terminating task")
        Process.exit(task, :leader_lost)
        GenServer.reply(from, :error)
        tasks = Map.delete(tasks, task)
        {:noreply, struct!(state, tasks: tasks)}

      :ok ->
        renew_deadline = Keyword.get(args, :renew_deadline, @renew_deadline)
        Process.send_after(self(), {:renew, task}, renew_deadline * 1000)
        {:noreply, state}
    end
  end

  defp acquire(conn, now, args) do
    lease_name = Keyword.fetch!(args, :name)
    lease_namespace = Keyword.fetch!(args, :namespace)
    holder_identity = Keyword.fetch!(args, :identity)
    duration = Keyword.get(args, :duration, @lease_duration)

    desired_lease = lease(lease_name, lease_namespace, holder_identity, duration, now)
    dbg(desired_lease)

    {:ok, lease} = find_or_create_lease(conn, desired_lease)
    ours? = our_lease?(lease, desired_lease)
    expired? = lease_expired?(now, lease)

    # not ours and not expired
    if not ours? && not expired? do
      Logger.error("couldn't acquire lock")
      :error
    else
      to_apply =
        desired_lease
        |> put_in(~w(metadata resourceVersion), lease["metadata"]["resourceVersion"])
        # use existing acquire time if it's our lease
        |> maybe_put(ours?, ~w(spec acquireTime), lease["spec"]["acquireTime"])

      case apply_lease(conn, to_apply) do
        {:ok, _} ->
          :ok

        {:error, err} ->
          Logger.error("failed to apply lease: #{inspect(err)}")
          :error
      end
    end
  end

  defp lease(lease_name, lease_namespace, holder_identity, duration, now) do
    spec = %{
      "holderIdentity" => holder_identity,
      "leaseDurationSeconds" => duration,
      "renewTime" => DateTime.to_iso8601(now),
      "acquireTime" => DateTime.to_iso8601(now)
    }

    :lease
    |> B.build_resource()
    |> B.name(lease_name)
    |> B.namespace(lease_namespace)
    |> B.spec(spec)
  end

  defp get_lease(conn, lease) do
    lease
    |> K8s.Client.get()
    |> K8s.Client.put_conn(conn)
    |> K8s.Client.run()
  end

  defp find_or_create_lease(conn, lease) do
    case lease
         |> K8s.Client.get()
         |> K8s.Client.put_conn(conn)
         |> K8s.Client.run() do
      {_, :not_found} ->
        create_lease(conn, lease)

      {:error, %APIError{reason: "NotFound"}} ->
        create_lease(conn, lease)

      {:error, %K8s.Operation.Error{message: "NotFound"}} ->
        create_lease(conn, lease)

      {:error, %K8s.Discovery.Error{message: _}} ->
        create_lease(conn, lease)

      {:error, :not_found} ->
        create_lease(conn, lease)

      {:ok, _} = result ->
        result

      {:error, _} = error ->
        error
    end
  end

  defp create_lease(conn, lease) do
    lease
    |> K8s.Client.create()
    |> K8s.Client.put_conn(conn)
    |> K8s.Client.run()
  end

  defp apply_lease(conn, lease) do
    lease
    |> K8s.Client.apply()
    |> K8s.Client.put_conn(conn)
    |> K8s.Client.run()
  end

  defp our_lease?(%{"spec" => old_lease_spec}, desired_lease) do
    String.length(old_lease_spec["holderIdentity"]) > 0 and
      old_lease_spec["holderIdentity"] == desired_lease["spec"]["holderIdentity"]
  end

  defp lease_expired?(now, %{"spec" => spec}) do
    {:ok, last_renew, 0} = DateTime.from_iso8601(spec["renewTime"])
    time_of_expiration = DateTime.add(last_renew, spec["leaseDurationSeconds"])

    DateTime.after?(time_of_expiration, now)
  end
end
