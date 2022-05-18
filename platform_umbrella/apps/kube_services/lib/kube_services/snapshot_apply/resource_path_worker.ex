defmodule KubeServices.SnapshotApply.ResourcePathWorker do
  use GenServer, restart: :temporary

  alias KubeServices.SnapshotApply.SnapshotWorker

  require Logger

  def start_link([resource_path, snapshot_worker_pid]) do
    GenServer.start_link(__MODULE__, %{
      snapshot_worker_pid: snapshot_worker_pid,
      resource_path: resource_path,
      connectiton: KubeExt.ConnectionPool.get()
    })
  end

  @impl true
  def init(state) do
    Process.flag(:trap_exit, true)
    send(self(), :maybe_apply)

    {:ok, state}
  end

  @impl true
  def handle_info(:maybe_apply, %{resource_path: rp} = state) do
    resource_state = KubeState.get_resource(rp.resource_value)

    if KubeExt.Hashing.get_hash(resource_state) == rp.hash do
      send(self(), {:success, :state_hash_match})
    else
      send(self(), :to_kube)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(:to_kube, %{connectiton: conn, resource_path: rp} = state) do
    {:ok, _} = KubeExt.apply_single(conn, rp.resource_value)
    send(self(), {:success, :applied})
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:success, reason},
        %{snapshot_worker_pid: worker_pid, resource_path: rp} = state
      ) do
    SnapshotWorker.path_success(worker_pid, rp, reason)
    {:stop, :done, state}
  end

  @impl true
  def terminate(reason, %{resource_path: rp, snapshot_worker_pid: worker_pid} = _state) do
    case reason do
      :done ->
        :ok

      _ ->
        SnapshotWorker.path_failure(worker_pid, rp, reason)
        :ok
    end
  end
end
