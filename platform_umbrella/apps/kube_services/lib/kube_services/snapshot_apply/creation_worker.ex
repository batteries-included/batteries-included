defmodule KubeServices.SnapshotApply.CreationWorker do
  use Oban.Worker,
    max_attempts: 3

  alias KubeServices.SnapshotApply.Steps
  alias KubeServices.SnapshotApply.SummarizeWorker

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{} = _args}) do
    snap = Steps.creation!()

    jobs =
      snap
      |> Steps.generation!()
      |> Steps.launch_resource_path_jobs()

    up_snap = Steps.update_applying!(snap)

    Logger.debug("Starting new snapshot #{up_snap.id} with #{length(jobs)} resource path jobs")

    SummarizeWorker.queue(up_snap.id)
  end

  def start!(opts \\ []) do
    %{} |> new(opts) |> Oban.insert!()
  end
end
