defmodule Server.Configs.PrometheusTest do
  use Server.DataCase

  import Server.Factory
  alias Server.Configs.RawConfig
  alias Server.Configs.Prometheus

  test "create_for_cluster" do
    cluster = insert(:kube_cluster)
    cluster_id = cluster.id

    {:ok, %RawConfig{} = raw_config} = Prometheus.create_for_cluster(cluster_id)
    assert raw_config.path == "/prometheus/base"
  end
end
