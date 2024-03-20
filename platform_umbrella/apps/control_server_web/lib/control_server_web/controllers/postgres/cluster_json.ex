defmodule ControlServerWeb.ClusterJSON do
  alias CommonCore.Postgres.Cluster
  alias CommonCore.Postgres.PGDatabase
  alias CommonCore.Postgres.PGUser

  @doc """
  Renders a list of clusters.
  """
  def index(%{clusters: clusters}) do
    %{data: for(cluster <- clusters, do: data(cluster))}
  end

  @doc """
  Renders a single cluster.
  """
  def show(%{cluster: cluster}) do
    %{data: data(cluster)}
  end

  defp data(%Cluster{} = cluster) do
    %{
      id: cluster.id,
      name: cluster.name,
      num_instances: cluster.num_instances,
      type: cluster.type,
      storage_size: cluster.storage_size,
      cpu_requested: cluster.cpu_requested,
      cpu_limits: cluster.cpu_limits,
      memory_limits: cluster.memory_limits,
      users: for(user <- cluster.users || [], do: data(user)),
      database: data(cluster.database)
    }
  end

  defp data(%PGUser{} = user) do
    # Never put credentials here
    %{
      username: user.username,
      roles: user.roles
    }
  end

  defp data(%PGDatabase{} = database) do
    %{
      name: database.name,
      owner: database.owner
    }
  end

  defp data(nil), do: nil
end
