defmodule KubeResources.RawCluster do
  def team_name(%{} = cluster), do: Map.get(cluster, :team_name, "pg")
  def cluster_name(%{} = cluster), do: Map.get(cluster, :name, "")
  def cluster_type(%{} = cluster), do: Map.get(cluster, :type, :default)
  def num_instances(%{} = cluster), do: Map.get(cluster, :num_instances, 1)
  def postgres_version(%{} = cluster), do: Map.get(cluster, :postgres_version, "14")
  def storage_size(%{} = cluster), do: Map.get(cluster, :storage_size, "500M")

  def spec_users(%{} = cluster) do
    cluster
    |> Map.get(:users, [])
    |> Enum.map(fn u -> {u.username, u.roles} end)
    |> Map.new()
  end

  def spec_databases(%{} = cluster) do
    cluster
    |> Map.get(:clusters, [])
    |> Enum.map(fn c -> {c.name, c.owner} end)
    |> Map.new()
  end

  def full_name(%{} = cluster) do
    team_name = team_name(cluster)
    cluster_name = cluster_name(cluster)
    "#{team_name}-#{cluster_name}"
  end
end
