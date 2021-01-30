defmodule Server.Configs.RunningSet do
  import Ecto.Query, warn: false
  alias Server.Configs

  def create_for_cluster(kube_cluster_id) do
    Configs.create_raw_config(%{
      kube_cluster_id: kube_cluster_id,
      path: "/running_set",
      content: %{}
    })
  end
end
