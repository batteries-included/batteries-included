defmodule Server.Configs.DefaultsTest do
  use Server.DataCase

  import Server.Factory
  alias Server.Configs.RawConfig
  alias Server.Configs.RunningSet

  test "create_running_set" do
    cluster = insert(:kube_cluster)
    cluster_id = cluster.id

    {:ok, %RawConfig{} = raw_config} = RunningSet.create_for_cluster(cluster.id)
    assert raw_config.content == %{"monitoring" => false}
    assert raw_config.path == "/running_set"
    assert raw_config.kube_cluster_id == cluster_id
  end
end
