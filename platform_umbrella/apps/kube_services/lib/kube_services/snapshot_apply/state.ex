defmodule KubeServices.SnapshotApply.State do
  use GenServer

  alias ControlServer.SnapshotApply, as: ControlSnapshotApply
  alias ControlServer.SnapshotApply.KubeSnapshot
  alias EventCenter.KubeSnapshot, as: SnapshotEventCenter

  require Logger

  def start_link([snapshot]) do
    GenServer.start_link(__MODULE__, %{
      kube_snapshot: snapshot
    })
  end

  @impl true
  def init(state) do
    state = %{state | kube_snapshot: get_or_create_snapshot(state)}
    {:ok, state}
  end

  def get_kube_snapshot(pid) do
    GenServer.call(pid, :get_snapshot)
  end

  def advance_kube_snapshot(pid), do: GenServer.call(pid, :advance_kube_snapshot)

  def path_success(pid, resource_path, reason),
    do: GenServer.cast(pid, {:path_success, resource_path, reason})

  def path_failure(pid, resource_path, reason),
    do: GenServer.cast(pid, {:path_failure, resource_path, reason})

  def count_outstanding(pid), do: GenServer.call(pid, :count_outstanding)

  def count_failed(pid), do: GenServer.call(pid, :count_failed)

  def success(pid), do: GenServer.cast(pid, :success)

  def failure(pid), do: GenServer.cast(pid, :failure)

  def add_notify(pid, target), do: GenServer.cast(pid, {:add_notify, target})

  @impl true
  def handle_call(:get_snapshot, _from, %{kube_snapshot: kube_snapshot} = state),
    do: {:reply, kube_snapshot, state}

  @impl true
  def handle_call(:count_outstanding, _from, %{kube_snapshot: kube_snapshot} = state),
    do: {:reply, count_resource_paths_outstanding(kube_snapshot), state}

  @impl true
  def handle_call(:count_failed, _from, %{kube_snapshot: kube_snapshot} = state),
    do: {:reply, count_resource_paths_failed(kube_snapshot), state}

  @impl true
  def handle_call(:advance_kube_snapshot, _from, %{kube_snapshot: snapshot} = state) do
    case snapshot.status do
      :applying ->
        # Applying is going to wait for all the resource paths to complete
        {:reply, {:ok, snapshot}, state}

      _ ->
        updated_snap = update_status(snapshot, KubeSnapshot.next_status(snapshot))

        {:reply, {:ok, updated_snap}, %{state | kube_snapshot: updated_snap}}
    end
  end

  @impl true
  def handle_cast({:path_success, resource_path, reason}, state) do
    update_path_success(resource_path, reason)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:path_failure, resource_path, reason}, state) do
    update_path_failure(resource_path, reason)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:success, %{kube_snapshot: snapshot} = state) do
    updated_snap = update_status(snapshot, :ok)

    broadcast(updated_snap)

    {:noreply, %{state | kube_snapshot: updated_snap}}
  end

  @impl true
  def handle_cast(:failure, %{kube_snapshot: snapshot} = state) do
    updated_snap = update_status(snapshot, :error)

    broadcast(updated_snap)

    {:noreply, %{state | kube_snapshot: updated_snap}}
  end

  defp get_or_create_snapshot(%{kube_snapshot: s}) when not is_nil(s), do: s

  defp get_or_create_snapshot(_) do
    with {:ok, snapshot} <- ControlSnapshotApply.create_kube_snapshot() do
      snapshot
    end
  end

  defp update_path_success(resource_path, r) do
    Logger.debug("Reporting success for path #{resource_path.path}")
    update_path(resource_path, r, true)
  end

  defp update_path_failure(resource_path, r) do
    Logger.debug("Reporting failure for path #{resource_path.path}")
    update_path(resource_path, r, false)
  end

  defp update_path(resource_path, r, is_success) do
    with {:ok, new_rp} <-
           ControlSnapshotApply.update_resource_path(resource_path, %{
             is_success: is_success,
             apply_result: r |> reason() |> String.slice(0, 200)
           }) do
      new_rp
    end
  end

  defp update_status(snapshot, status) do
    with {:ok, new_snap} <-
           ControlSnapshotApply.update_kube_snapshot(snapshot, %{
             status: status
           }) do
      Logger.debug("Advanced #{new_snap.id} new satus = #{new_snap.status}")

      new_snap
    end
  end

  defp count_resource_paths_outstanding(kube_snapshot) do
    kube_snapshot
    |> ControlSnapshotApply.resource_paths_for_snapshot()
    |> ControlSnapshotApply.resource_paths_outstanding()
    |> ControlSnapshotApply.count_paths() || 0
  end

  defp count_resource_paths_failed(kube_snapshot) do
    kube_snapshot
    |> ControlSnapshotApply.resource_paths_for_snapshot()
    |> ControlSnapshotApply.resource_paths_failed()
    |> ControlSnapshotApply.count_paths() || 0
  end

  def broadcast(snapshot) do
    :ok = SnapshotEventCenter.broadcast(snapshot)
  end

  def reason(reason_atom) when is_atom(reason_atom), do: Atom.to_string(reason_atom)
  def reason(reason_string) when is_binary(reason_string), do: reason_string
  def reason(obj), do: inspect(obj)
end
