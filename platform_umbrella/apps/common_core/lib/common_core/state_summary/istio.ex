defmodule CommonCore.StateSummary.Istio do
  @moduledoc false

  alias CommonCore.StateSummary
  alias CommonCore.StateSummary.FromKubeState

  def virtual_services(%StateSummary{} = summary) do
    FromKubeState.all_resources(summary, :virtual_service)
  end

  def gateways(%StateSummary{} = summary) do
    FromKubeState.all_resources(summary, :gateway)
  end
end
