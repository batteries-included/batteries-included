defmodule KubeRawResources.DatabaseSettings do
  @moduledoc """
  Module for extracting the setting from a map usually a json map from the BaseService ecto
  """
  @namepace "battery-core"

  @pg_operator_name "battery-pg-operator"
  @pg_operator_pod_account_name "battery-pg-pod"
  @pg_operator_image "registry.opensource.zalan.do/acid/postgres-operator"
  @pg_operator_version "v1.7.1"
  @pg_operator_cluster_label "battery-pg-cluster"

  def namespace(config), do: Map.get(config, "namespace", @namepace)
  def bootstrap_clusters(config), do: Map.get(config, "bootstrap.clusters", [])

  def pg_operator_name(config), do: Map.get(config, "pg_operator.name", @pg_operator_name)

  def pg_operator_pod_account_name(config),
    do: Map.get(config, "pg_operator.pod_account_name", @pg_operator_pod_account_name)

  def pg_operator_image(config), do: Map.get(config, "pg_operator.image", @pg_operator_image)

  def pg_operator_version(config),
    do: Map.get(config, "pg_operator.version", @pg_operator_version)

  def cluster_name_label(config),
    do: Map.get(config, "pg_operator.cluster_label", @pg_operator_cluster_label)
end
