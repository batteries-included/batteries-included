defmodule Server.Configs.Adoption do
  import Ecto.Query, warn: false
  alias Server.Configs

  def adopt(config) do
    config
    |> Configs.update_raw_config(%{content: %{"is_adopted" => true}})
  end

  def for_kube_cluster!(kube_cluster_id) do
    Configs.get_cluster_path!(kube_cluster_id, "/adoption")
  end

  def create_for_cluster(kube_cluster_id) do
    Configs.create_raw_config(%{
      kube_cluster_id: kube_cluster_id,
      path: "/adoption",
      content: %{is_adopted: false}
    })
  end
end
