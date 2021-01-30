defmodule Server.Configs.Defaults do
  import Ecto.Query, warn: false
  alias Server.Configs

  def create_all(kube_cluster_id) do
    {:ok, adoption_config} = Configs.Defaults.create_adoption(kube_cluster_id)
    {:ok, running_set} = Configs.Defaults.create_running_set(kube_cluster_id)
    {:ok, running_set: running_set, adoption_config: adoption_config}
  end

  def create_adoption(kube_cluster_id) do
    Configs.create_raw_config(%{
      kube_cluster_id: kube_cluster_id,
      path: "/adoption",
      content: %{is_adopted: false}
    })
  end

  def create_running_set(kube_cluster_id) do
    Configs.create_raw_config(%{
      kube_cluster_id: kube_cluster_id,
      path: "/running_set",
      content: %{}
    })
  end
end
