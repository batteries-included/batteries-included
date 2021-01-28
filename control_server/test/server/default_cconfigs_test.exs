defmodule Server.DefaultConfigsTest do
  use Server.DataCase

  import Server.Factory
  alias Server.DefaultConfigs
  alias Server.Configs.RawConfig

  test "create_adoption" do
    cluster = insert(:kube_cluster)
    cluster_id = cluster.id

    {:ok, %RawConfig{} = raw_config} = DefaultConfigs.create_adoption(cluster)
    assert raw_config.content == %{}
    assert raw_config.path == "/adoption"
    assert raw_config.kube_cluster_id == cluster_id
  end

  test "create_running_set" do
    cluster = insert(:kube_cluster)
    cluster_id = cluster.id

    {:ok, %RawConfig{} = raw_config} = DefaultConfigs.create_running_set(cluster)
    assert raw_config.content == %{}
    assert raw_config.path == "/running_services"
    assert raw_config.kube_cluster_id == cluster_id
  end
end
