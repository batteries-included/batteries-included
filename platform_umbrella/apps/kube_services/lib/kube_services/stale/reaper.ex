defmodule KubeServices.Stale.Reaper do
  use GenServer
  use TypedStruct

  import K8s.Resource.FieldAccessors

  alias CommonCore.ApiVersionKind
  alias KubeServices.Stale
  alias KubeServices.ResourceDeleter

  require Logger

  @me __MODULE__
  @state_opts [
    :waiting_count,
    :delay,
    :running
  ]

  typedstruct module: State do
    field :waiting_count, integer(), default: 0
    field :delay, integer(), default: 10_000
    field :running, boolean(), default: true
  end

  def start_link(opts \\ []) do
    {state_opts, opts} =
      opts
      |> Keyword.put_new(:name, @me)
      |> Keyword.split(@state_opts)

    GenServer.start_link(__MODULE__, state_opts, opts)
  end

  @impl GenServer
  def init(opts) do
    {:ok, struct(State, opts)}
  end

  @impl GenServer
  def handle_info({:maybe_reap, _suspected_stale}, %State{running: false} = state) do
    Logger.warning("Stale worker not running.")
    {:noreply, %State{state | waiting_count: state.waiting_count - 1}}
  end

  def handle_info({:maybe_reap, suspected_stale}, state) do
    Logger.warning("Stale worker running checking on #{length(suspected_stale)}.")

    if can_delete_safe?() do
      res =
        suspected_stale
        |> verify_stale()
        |> delete()

      Logger.info("Stale reap result = #{res}")
    end

    {:noreply, %State{state | waiting_count: state.waiting_count - 1}}
  end

  @impl GenServer
  def handle_call({:queue_reap, potential_stale}, _from, %State{delay: delay} = state) do
    _timer_ref = Process.send_after(self(), {:maybe_reap, potential_stale}, delay)
    {:reply, :ok, %State{state | waiting_count: state.waiting_count + 1}}
  end

  def queue_reap(target \\ @me, potential_stale) do
    # Send the potential stale resources into the genserver.
    # From there we'll use `Process.send_after()` to  queue checking if they are still stale
    GenServer.call(target, {:queue_reap, potential_stale})
  end

  defp can_delete_safe? do
    res = Stale.can_delete_safe?()
    Logger.debug("Can delete safe = #{res}")
    res
  end

  defp verify_stale(suspected_stale) do
    Logger.debug("Verifying that resources are still stale")
    seen_res_set = Stale.recent_resource_map_set()

    Enum.filter(suspected_stale, fn resource ->
      Stale.is_stale(resource, seen_res_set)
    end)
  end

  defp delete([] = _verified_stale) do
    Logger.info("There are no verified stale resources. Returning success")
    :ok
  end

  defp delete([_ | _] = verified_stale) do
    Logger.info("Going to delete #{length(verified_stale)} resources that are stale")

    all_good =
      verified_stale
      |> Enum.map(fn res ->
        kind = ApiVersionKind.resource_type!(res)
        name = name(res)
        namespace = namespace(res)

        case ResourceDeleter.delete(res) do
          {:ok, _} ->
            Logger.info("Successsfully deleted, #{kind} #{namespace} #{name}")
            :ok

          result ->
            Logger.warning(
              "Un-expected result deleting stale kind: #{kind} name: #{name} namespace: #{namespace} Result = #{inspect(result)}",
              kind: kind,
              namespace: namespace,
              name: name,
              result: result
            )

            result
        end
      end)
      |> Enum.all?(fn v -> v == :ok end)

    if all_good, do: :ok, else: {:error, :error_deleting}
  end
end
