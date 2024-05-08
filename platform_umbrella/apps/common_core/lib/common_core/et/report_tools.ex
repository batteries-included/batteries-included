defmodule CommonCore.ET.ReportTools do
  @moduledoc false
  alias CommonCore.StateSummary.FromKubeState

  def count_pods_by(state_summary, func) do
    pods = FromKubeState.all_resources(state_summary, :pod)

    pods
    |> Enum.group_by(func)
    |> Map.new(fn {key, pods} -> {key, length(pods)} end)
  end
end
