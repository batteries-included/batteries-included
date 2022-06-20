defmodule KubeServices.Stale.InitialWorker do
  use Oban.Worker,
    max_attempts: 3,
    unique: [fields: [:queue, :worker], period: 60]

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{} = _args}) do
    # find the stale resources now.
    possible_stale = KubeServices.Stale.find_stale()

    # Enque a run that will check again.
    %{stale: possible_stale}
    |> KubeServices.Stale.PerformWorker.new(schedule_in: 10)
    |> Oban.insert()
  end
end
