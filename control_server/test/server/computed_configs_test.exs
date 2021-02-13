defmodule Server.Configs.ComputedConfigsTest do
  use Server.DataCase

  import Server.Factory

  alias Server.ComputedConfigs
  alias Server.Configs.Defaults

  test "get" do
    cluster = insert(:kube_cluster)
    {:ok, _} = Defaults.create_all(cluster.id)

    {:ok, config} = ComputedConfigs.get(cluster.id, "/prometheus/main")
    assert config.path == "/prometheus/main"
  end
end
