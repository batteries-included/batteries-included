defmodule KubeRawResources.DataSettings do
  @moduledoc """
  Module for extracting the setting from a map usually a json map from the BaseService ecto
  """

  import KubeExt.MapSettings

  @namepace "battery-core"
  @public_namepace "battery-data"

  @pg_operator_image "registry.opensource.zalan.do/acid/postgres-operator:v1.8.2"

  @redis_operator_image "quay.io/spotahome/redis-operator:v1.1.1"

  @ceph_image "quay.io/ceph/ceph:v17.2.3"

  setting(:namespace, :namespace, @namepace)

  setting(:public_namespace, :namespace, @public_namepace)

  setting(:bootstrap_clusters, :bootstrap_clusters, [])

  setting(:pg_operator_image, :image, @pg_operator_image)

  setting(:redis_operator_image, :image, @redis_operator_image)

  setting(:ceph_image, :ceph_image, @ceph_image)
end
