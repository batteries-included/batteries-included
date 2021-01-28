defmodule Server.DefaultConfigs do
  import Ecto.Query, warn: false
  alias Server.Configs

  def create_adoption(cluster) do
    Configs.create_raw_config(%{kube_cluster_id: cluster.id, path: "/adoption", content: %{}})
  end

  def create_running_set(cluster) do
    Configs.create_raw_config(%{
      kube_cluster_id: cluster.id,
      path: "/running_services",
      content: %{}
    })
  end
end
