defmodule KubeServices.Timeline.PodStatus do
  @moduledoc """
  Responsible for tracking pod statuses.

  It maintains a mapping of pod to a status. The status is determined using the
  information in `.spec.conditions`. For details, see `status/1`.
  """
  use GenServer

  import K8s.Resource

  alias KubeServices.SystemState.Summarizer

  require Logger

  @me __MODULE__
  @init_args [:table_name, :initial_sync_delay]

  @type option :: [table_name: atom(), initial_sync_delay: non_neg_integer()]
  @type state :: {:ets.table()}
  @type condition :: %{type: String.t(), status: boolean()}
  @type resource :: %{
          metadata: %{name: String.t(), namespace: String.t()},
          status: %{conditions: [condition()]}
        }
  @type key :: {String.t(), String.t()}
  @type status ::
          :ready | :containers_ready | :initialized | :pod_has_network | :pod_scheduled | :unknown

  @doc """
  Start the PodStatus server.
  """
  @spec start_link(opts :: [option() | GenServer.options()]) :: GenServer.on_start()
  def start_link(opts \\ []) do
    {init_args, opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@init_args)

    {:ok, pid} = result = GenServer.start_link(@me, init_args, opts)
    Logger.debug("#{@me} GenServer started with #{inspect(pid)}, opts: #{inspect(opts)}")
    result
  end

  @impl GenServer
  @spec init(opts :: [option()]) :: {result :: atom(), initial_state :: state()}
  def init(opts) do
    ets_table = :ets.new(opts[:table_name], [:set, :named_table, read_concurrency: true])
    delay = Keyword.get(opts, :initial_sync_delay, 10_000)

    if delay > 0 do
      _ref = Process.send_after(@me, :sync, delay)
      # return :ok from this block to make dialyzer
      # realize we handled the ref above, by ignoring it.
      :ok
    end

    {:ok, {ets_table}}
  end

  # sync our mapping from a summarizer
  @impl GenServer
  @spec handle_info(msg :: :sync, state :: state()) :: {action :: :noreply, newstate :: state()}
  def handle_info(:sync, state) do
    :kube_state
    |> Summarizer.cached_field()
    |> Map.get(:pod)
    |> Enum.each(&upsert/1)

    {:noreply, state}
  end

  # get the mapping for a resource from its key
  @impl GenServer
  @spec handle_call(
          request :: {:get, key()},
          from :: GenServer.from(),
          state :: state()
        ) ::
          {action :: :reply, response :: {:ok, {key(), status()}}, state()}
  def handle_call({:get, key}, _from, {ets_table}), do: {:reply, {:ok, get(ets_table, key)}, {ets_table}}

  # dump the interal state. for troubleshooting
  @impl GenServer
  @spec handle_call(
          request :: :dump,
          from :: GenServer.from(),
          state :: state()
        ) ::
          {action :: :reply, response :: {:ok, [{key(), status()}], state()}}
  def handle_call(:dump, _from, {ets_table}) do
    {:reply, {:ok, :ets.tab2list(ets_table)}, {ets_table}}
  end

  # async upsert of new mapping
  @impl GenServer
  @spec handle_cast(
          request :: {:upsert, key(), status()},
          state :: state()
        ) ::
          {action :: :noreply, state()}
  def handle_cast({:upsert, key, status}, {ets_table}) do
    :ets.insert(ets_table, {key, status})
    Logger.debug("Upserted status: #{status} for pod: #{inspect(key)}")
    {:noreply, {ets_table}}
  end

  # async delete mapping
  @impl GenServer
  @spec handle_cast(
          request :: {:delete, key()},
          state :: state()
        ) ::
          {action :: :noreply, state()}
  def handle_cast({:delete, key}, {ets_table}) do
    :ets.delete(ets_table, key)
    Logger.debug("Deleted pod status: #{inspect(key)}")
    {:noreply, {ets_table}}
  end

  @doc """
  Determine if the status has changed for a resource.
  """
  @spec status_changed?(table :: :ets.table(), resource()) ::
          {changed :: boolean(), status()}
  def status_changed?(table, resource) do
    key = key(resource)
    current_status = status(resource)
    {^key, status} = get(table, key)
    {current_status != status, current_status}
  end

  @doc """
  Create or update the pod -> status mapping for the given resource.
  """
  @spec upsert(GenServer.server(), resource()) :: :ok
  def upsert(target \\ @me, resource) do
    # get the key and status outside of the server for memory mgmt purposes
    GenServer.cast(target, {:upsert, key(resource), status(resource)})
  end

  @doc """
  Delete the pod -> status mapping for the given resource.
  """
  @spec delete(GenServer.server(), resource()) :: :ok
  def delete(target \\ @me, resource) do
    # get the key outside of the server for memory mgmt purposes
    GenServer.cast(target, {:delete, key(resource)})
  end

  @doc """
  Dump the internal pod -> status mapping.

  This should only be used for debugging / troubleshooting.
  """
  @spec dump(GenServer.server()) :: [{key(), status()}]
  def dump(target \\ @me) do
    {:ok, list} = GenServer.call(target, :dump)
    list
  end

  # get the mapping for a key from the ets table
  @spec get(:ets.table(), key()) :: {key(), status()}
  defp get(table, key) do
    result = :ets.lookup(table, key)

    case result do
      [{^key, _} = entry] ->
        entry

      _ ->
        {key, :unknown}
    end
  end

  # standard key generation for a resource
  @spec key(resource()) :: key()
  defp key(resource) do
    {namespace(resource), name(resource)}
  end

  # For a pod resource, get the current status
  # https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-conditions
  @spec status(resource()) :: status()
  defp status(resource) do
    conditions = get_in(resource, ["status", "conditions"])

    case conditions do
      nil ->
        :unknown

      _ ->
        conditions
        |> Enum.filter(&(&1["status"] == "True"))
        |> Enum.reduce(%{}, &Map.put(&2, &1["type"], &1["status"]))
        |> status_for_conditions()
    end
  end

  # given a list of 'True' conditions, find the "highest" priority status
  @spec status_for_conditions(map()) :: status()
  defp status_for_conditions(map_of_true_conditions)
  defp status_for_conditions(%{"Ready" => _}), do: :ready
  defp status_for_conditions(%{"ContainersReady" => _}), do: :containers_ready
  defp status_for_conditions(%{"Initialized" => _}), do: :initialized
  defp status_for_conditions(%{"PodHasNetwork" => _}), do: :pod_has_network
  defp status_for_conditions(%{"PodScheduled" => _}), do: :pod_scheduled
  defp status_for_conditions(_), do: :unknown
end
