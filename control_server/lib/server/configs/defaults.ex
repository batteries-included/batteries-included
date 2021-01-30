defmodule Server.Configs.Defaults do
  import Ecto.Query, warn: false

  alias Server.Configs.Adoption
  alias Server.Configs.RunningSet

  def create_all(kube_cluster_id) do
    {:ok, adoption_config} = Adoption.create_for_cluster(kube_cluster_id)
    {:ok, running_set} = RunningSet.create_for_cluster(kube_cluster_id)
    {:ok, running_set: running_set, adoption_config: adoption_config}
  end
end
