defmodule KubeServices.SystemState do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    children = [
      KubeServices.SystemState.Summarizer,
      KubeServices.SystemState.SummaryHosts,
      KubeServices.SystemState.SummaryBatteries
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
