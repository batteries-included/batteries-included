defmodule KubeServices.SnapshotApply.Worker do
  use Oban.Worker,
    max_attempts: 3

  alias KubeServices.SnapshotApply.KubeApply
  alias KubeServices.SystemState.Summarizer

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{} = _args}) do
    # Prepare
    state = Summarizer.new()
    kube_snap = KubeApply.prepare()

    # Generation phase
    # Write everything to the database that we will be targeting
    # however as an optimization, we pass that data along to the
    # apply phase rather than re-fetching it from the db.
    {:ok, gen_payload} = KubeApply.generate(kube_snap, state)

    # Apply phase.
    # Take the target database state and try applying it to the system.
    {:ok, _} = KubeApply.apply(kube_snap, gen_payload)
  end

  @spec start!(keyword) :: Oban.Job.t()
  def start!(opts \\ []) do
    %{} |> new(opts) |> Oban.insert!()
  end
end
