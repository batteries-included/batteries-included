defmodule KubeServices.Stale.InitialWorker do
  use Oban.Worker,
    max_attempts: 3

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{} = _args}) do
    # find the stale resources now.
    possible_stale = KubeServices.Stale.find_potential_stale()

    Logger.debug("length(possible_stale)= #{length(possible_stale)}")

    if Enum.empty?(possible_stale) do
      Logger.debug("No possible stale resources")
      :ok
    else
      Logger.info("Found possible stale resource scheduling job to check")
      # Enque a run that will check again.
      %{stale: possible_stale}
      |> KubeServices.Stale.PerformWorker.new(schedule_in: 10)
      |> Oban.insert()
    end
  end
end
