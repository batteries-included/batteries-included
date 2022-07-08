defmodule KubeRawResources.DataSettings do
  @moduledoc """
  Module for extracting the setting from a map usually a json map from the BaseService ecto
  """

  import KubeExt.MapSettings

  @namepace "battery-core"
  @public_namepace "battery-data"

  @pg_operator_image "registry.opensource.zalan.do/acid/postgres-operator:v1.8.2"
  @pg_operator_cluster_label "battery-pg-cluster"

  @redis_operator_image "quay.io/spotahome/redis-operator:v1.1.1"

  setting(:namespace, :namespace, @namepace)

  setting(:public_namespace, :namespace, @public_namepace)

  setting(:bootstrap_clusters, :bootstrap_clusters, [])

  setting(:pg_operator_image, :image, @pg_operator_image)
  setting(:pg_cluster_label, :cluster_label, @pg_operator_cluster_label)

  setting(:redis_operator_image, :image, @redis_operator_image)
end
