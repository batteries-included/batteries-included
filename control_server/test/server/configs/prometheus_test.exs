defmodule Server.Configs.PrometheusTest do
  use Server.DataCase

  import Server.Factory
  alias Server.Configs.Prometheus
  alias Server.Configs.RawConfig

  test "create_for_cluster" do
    cluster = insert(:kube_cluster)
    cluster_id = cluster.id

    {:ok, %RawConfig{} = raw_config} = Prometheus.create_for_cluster(cluster_id)
    assert raw_config.path == "/prometheus/base"
  end

  test "base_config" do
    cluster = insert(:kube_cluster)
    cluster_id = cluster.id
    Prometheus.create_for_cluster(cluster_id)

    raw_config = Prometheus.base_config!(cluster_id)
    assert raw_config.path == "/prometheus/base"
  end
end
