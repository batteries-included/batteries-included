defmodule KubeRawResource.RawCluster do
  def team_name(%{} = cluster), do: cluster.team_name || "pg"

  def full_name(%{} = cluster) do
    team_name = team_name(cluster)
    "#{team_name}-#{cluster.name}"
  end
end
