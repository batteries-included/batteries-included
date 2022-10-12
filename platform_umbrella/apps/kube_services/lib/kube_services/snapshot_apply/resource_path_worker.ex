defmodule KubeServices.SnapshotApply.ResourcePathWorker do
  use Oban.Worker,
    queue: :kube,
    max_attempts: 3

  alias KubeServices.SnapshotApply.Steps

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id} = _args}) do
    rp = Steps.get_rp(id)
    result = Steps.apply_resource_path(rp)
    {:ok, _} = Steps.update_resource_path(rp, result)
    KubeServices.SnapshotApply.SummarizeWorker.queue(rp.kube_snapshot_id)
  end
end
