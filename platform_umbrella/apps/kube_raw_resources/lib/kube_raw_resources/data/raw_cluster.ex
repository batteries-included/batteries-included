defmodule KubeRawResources.RawCluster do
  alias KubeRawResources.DataSettings

  def team_name(%{} = cluster), do: Map.get(cluster, :team_name, "pg")
  def cluster_name(%{} = cluster), do: Map.get(cluster, :name, "")
  def cluster_type(%{} = cluster), do: Map.get(cluster, :type, :default)
  def num_instances(%{} = cluster), do: Map.get(cluster, :num_instances, 1)
  def postgres_version(%{} = cluster), do: Map.get(cluster, :postgres_version, "13")
  def storage_size(%{} = cluster), do: Map.get(cluster, :storage_size, "500M")

  def users(%{} = cluster), do: Map.get(cluster, :users, %{}) || %{}
  def databases(%{} = cluster), do: Map.get(cluster, :databases, %{}) || %{}

  def full_name(%{} = cluster) do
    team_name = team_name(cluster)
    cluster_name = cluster_name(cluster)
    "#{team_name}-#{cluster_name}"
  end

  def namespace(%{} = cluster, config \\ %{}) do
    case cluster_type(cluster) do
      :internal -> DataSettings.namespace(config)
      _ -> DataSettings.public_namespace(config)
    end
  end
end
