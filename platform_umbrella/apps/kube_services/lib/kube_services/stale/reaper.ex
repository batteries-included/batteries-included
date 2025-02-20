defmodule KubeServices.Stale.Reaper do
  @moduledoc false
  use GenServer
  use TypedStruct

  alias CommonCore.Resources.FieldAccessors
  alias KubeServices.ResourceDeleter
  alias KubeServices.Stale

  require Logger

  @me __MODULE__
  @state_opts [
    :waiting_count,
    :delay,
    :running
  ]

  typedstruct module: State do
    field :waiting_count, integer(), default: 0
    field :delay, integer(), default: 900_000
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
    # queue the initial worker to run pretty soon after startup
    schedule_worker(1000)

    state = struct!(State, opts)

    Logger.debug("Starting KubServices.Stale.Reaper")
    {:ok, state}
  end

  @impl GenServer
  def handle_info({:find_possible_stale}, %State{delay: delay} = state) do
    possible_stale = Stale.find_potential_stale()

    Logger.debug("length(possible_stale)= #{length(possible_stale)}")

    added =
      if Enum.empty?(possible_stale) do
        Logger.debug("No possible stale resources")
        0
      else
        Logger.info("Found possible stale resource(s). Scheduling job to check")
        Process.send_after(self(), {:maybe_reap, possible_stale}, delay)
        1
      end

    # Enque a run that will check again.
    schedule_worker(60_000)
    {:noreply, %{state | waiting_count: state.waiting_count + added}}
  end

  @impl GenServer
  def handle_info({:maybe_reap, _suspected_stale}, %State{running: false} = state) do
    Logger.warning("Stale worker not running.")
    {:noreply, %{state | waiting_count: state.waiting_count - 1}}
  end

  @impl GenServer
  def handle_info({:maybe_reap, suspected_stale}, state) do
    Logger.warning("Stale worker running checking on #{length(suspected_stale)}.")

    if can_delete_safe?() do
      res =
        suspected_stale
        |> verify_stale()
        |> delete()

      Logger.info("Stale reap result = #{inspect(res)}")
    end

    {:noreply, %{state | waiting_count: state.waiting_count - 1}}
  end

  defp schedule_worker(delay) do
    Process.send_after(self(), {:find_possible_stale}, delay)
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
      Stale.stale?(resource, seen_res_set)
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
        summary = FieldAccessors.summary(res)

        case ResourceDeleter.delete(res) do
          {:ok, _} ->
            Logger.info("Successsfully deleted, #{inspect(summary)}")
            :ok

          result ->
            Logger.warning(
              "Un-expected result deleting stale kind: #{inspect(summary)}. Result = #{inspect(result)}",
              kind: summary.kind,
              namespace: summary.namespace,
              name: summary.name,
              result: result
            )

            result
        end
      end)
      |> Enum.all?(fn v -> v == :ok end)

    if all_good, do: :ok, else: {:error, :error_deleting}
  end
end
