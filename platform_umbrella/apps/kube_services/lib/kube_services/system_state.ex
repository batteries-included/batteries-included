defmodule KubeServices.SystemState do
  @moduledoc false
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    should_refresh = Keyword.get(opts, :should_refresh, true)

    children = [
      KubeServices.SystemState.KeycloakSummarizer,
      {KubeServices.SystemState.Summarizer, [should_refresh: should_refresh]},
      KubeServices.SystemState.SummaryHosts,
      KubeServices.SystemState.SummaryBatteries
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
