defmodule KubeServices.SnapshotApply.SnapshotWorker do
  use GenServer, restart: :temporary

  alias KubeServices.SnapshotApply.State
  alias KubeServices.SnapshotApply.Steps

  require Logger

  def start_link([state_pid]) do
    GenServer.start_link(__MODULE__, %{state_pid: state_pid, outstanding: 0})
  end

  @impl true
  def init(state) do
    send(self(), :next_step)
    {:ok, state}
  end

  def path_success(pid, resource_path, reason) do
    GenServer.cast(pid, {:path_success, resource_path, reason})
    :ok
  end

  def path_failure(pid, resource_path, reason) do
    GenServer.cast(pid, {:path_failure, resource_path, reason})
    :ok
  end

  @impl true
  def handle_info(:next_step, %{state_pid: state_pid} = state) do
    kube_snapshot = state_get_kube_snapshot(state_pid)

    perform_next_step(kube_snapshot.status, kube_snapshot)

    with {:ok, snap} <- state_advance_status(state_pid) do
      case snap.status do
        :application ->
          count = state_count_outstanding(state_pid)
          state = %{state | outstanding: count}

          if count == 0 do
            send(self(), :finish)
          else
            send(self(), :next_step)
          end

          {:noreply, state}

        :applying ->
          {:noreply, state}

        _ ->
          send(self(), :next_step)
          {:noreply, state}
      end
    end
  end

  def handle_info(:finish, %{state_pid: state_pid} = state) do
    case state_count_failed(state_pid) do
      0 ->
        state_success(state_pid)

      _ ->
        state_failure(state_pid)
    end

    {:stop, :done, state}
  end

  @impl true
  def handle_cast({:path_success, resource_path, reason}, %{state_pid: state_pid} = state) do
    state_path_success(state_pid, resource_path, reason)

    {:noreply, decrease_outstanding(state)}
  end

  @impl true
  def handle_cast({:path_failure, resource_path, reason}, %{state_pid: state_pid} = state) do
    state_path_failure(state_pid, resource_path, reason)
    {:noreply, decrease_outstanding(state)}
  end

  defp perform_next_step(:creation, kube_snapshot), do: Steps.creation(kube_snapshot)
  defp perform_next_step(:generation, kube_snapshot), do: Steps.generation(kube_snapshot)

  defp perform_next_step(:application, kube_snapshot),
    do: Steps.application(kube_snapshot, self())

  defp perform_next_step(:applying, _kube_snapshot),
    do: Steps.apply()

  defp perform_next_step(_, _kube_snapshot), do: nil

  defp state_get_kube_snapshot(state_pid), do: State.get_kube_snapshot(state_pid)
  defp state_advance_status(state_pid), do: State.advance_kube_snapshot(state_pid)

  defp state_path_success(state_pid, resouce_path, reason),
    do: State.path_success(state_pid, resouce_path, reason)

  defp state_path_failure(state_pid, resouce_path, reason),
    do: State.path_failure(state_pid, resouce_path, reason)

  defp state_count_outstanding(state_pid), do: State.count_outstanding(state_pid)
  defp state_count_failed(state_pid), do: State.count_failed(state_pid)

  defp state_failure(state_pid), do: State.failure(state_pid)
  defp state_success(state_pid), do: State.success(state_pid)

  defp decrease_outstanding(%{outstanding: cnt} = state) do
    cnt = cnt - 1
    state = %{state | outstanding: cnt}

    if cnt == 0 do
      send(self(), :finish)
    end

    state
  end
end
