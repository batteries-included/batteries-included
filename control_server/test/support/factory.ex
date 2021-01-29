defmodule Server.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: Server.Repo

  def kube_cluster_factory do
    %Server.Clusters.KubeCluster{
      adopted: true,
      external_uid: sequence("external_uid-"),
    }
  end

  def raw_config_factory do
    %Server.Configs.RawConfig{
      path: sequence("/config/path-"),
      content: %{},
      kube_cluster: build(:kube_cluster)
    }
  end
end
