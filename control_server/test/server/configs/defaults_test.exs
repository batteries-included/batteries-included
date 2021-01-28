defmodule Server.DefaultConfigsTest do
  use Server.DataCase

  import Server.Factory
  alias Server.Configs.Defaults
  alias Server.Configs.RawConfig

  test "create_adoption" do
    cluster = insert(:kube_cluster)
    cluster_id = cluster.id

    {:ok, %RawConfig{} = raw_config} = Defaults.create_adoption(cluster)
    assert raw_config.content == %{}
    assert raw_config.path == "/adoption"
    assert raw_config.kube_cluster_id == cluster_id
  end

  test "create_running_set" do
    cluster = insert(:kube_cluster)
    cluster_id = cluster.id

    {:ok, %RawConfig{} = raw_config} = Defaults.create_running_set(cluster)
    assert raw_config.content == %{}
    assert raw_config.path == "/running_set"
    assert raw_config.kube_cluster_id == cluster_id
  end
end
