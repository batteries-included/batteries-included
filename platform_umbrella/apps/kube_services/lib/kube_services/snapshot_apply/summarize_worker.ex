defmodule KubeServices.SnapshotApply.SummarizeWorker do
  use Oban.Worker,
    max_attempts: 3,
    unique: [period: 300, states: [:available, :scheduled]]

  alias ControlServer.SnapshotApply
  alias KubeServices.SnapshotApply.Steps

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"id" => id} = _args}) do
    snap = SnapshotApply.get_preloaded_kube_snapshot!(id)
    new_snap = Steps.summarize!(snap)

    if new_snap.status == :applying do
      {:postpone, 10}
    else
      :ok
    end
  end

  def queue(id) do
    %{"id" => id} |> new(schedule_in: 5, replace: [:scheduled_at]) |> Oban.insert()
  end
end
