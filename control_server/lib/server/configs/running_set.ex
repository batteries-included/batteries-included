defmodule Server.Configs.RunningSet do
  import Ecto.Query, warn: false
  alias Server.Configs

  def for_kube_cluster!(kube_cluster_id) do
    Configs.get_cluster_path!(kube_cluster_id, "/running_set")
  end

  def create_for_cluster(kube_cluster_id) do
    Configs.create_raw_config(%{
      kube_cluster_id: kube_cluster_id,
      path: "/running_set",
      content: %{"monitoring" => false}
    })
  end

  def set_running(config, service_name, is_running \\ true) do
    new_content = %{config.content | service_name => is_running}

    config
    |> Configs.update_raw_config(%{content: new_content})
  end
end
