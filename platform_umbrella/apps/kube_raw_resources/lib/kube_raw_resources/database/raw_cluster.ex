defmodule KubeRawResources.RawCluster do
  alias KubeRawResources.DatabaseSettings

  def team_name(%{} = cluster), do: Map.get(cluster, :team_name, "pg")

  defp cluster_name(%{} = cluster), do: Map.get(cluster, :name, "")

  defp cluster_type(%{} = cluster), do: Map.get(cluster, :type, :default)

  def full_name(%{} = cluster) do
    team_name = team_name(cluster)
    cluster_name = cluster_name(cluster)
    "#{team_name}-#{cluster_name}"
  end

  def namespace(%{} = cluster, config \\ %{}) do
    case cluster_type(cluster) do
      :internal -> DatabaseSettings.namespace(config)
      _ -> DatabaseSettings.public_namespace(config)
    end
  end
end
