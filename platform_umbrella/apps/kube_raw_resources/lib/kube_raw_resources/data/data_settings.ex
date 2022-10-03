defmodule KubeRawResources.DataSettings do
  @moduledoc """
  Module for extracting the setting from a map usually a json map from the  battery ecto
  """

  import KubeExt.MapSettings

  @namepace "battery-core"
  @public_namepace "battery-data"

  @pg_operator_image "registry.opensource.zalan.do/acid/postgres-operator:v1.8.2"
  @pg_image "registry.opensource.zalan.do/acid/spilo-14:2.1-p7"
  @pg_logical_backup_image "registry.opensource.zalan.do/acid/logical-backup:v1.8.2"
  @pg_bouncer_image "registry.opensource.zalan.do/acid/pgbouncer:master-24"

  @redis_operator_image "quay.io/spotahome/redis-operator:v1.2.1"

  @ceph_image "quay.io/ceph/ceph:v17.2.3"

  setting(:namespace, :namespace, @namepace)

  setting(:public_namespace, :namespace, @public_namepace)

  setting(:bootstrap_clusters, :bootstrap_clusters, [])

  setting(:pg_image, :image, @pg_image)
  setting(:pg_operator_image, :operator_image, @pg_operator_image)
  setting(:pg_backup_image, :backup_image, @pg_logical_backup_image)
  setting(:pg_bouncer_image, :bouncer_imager, @pg_bouncer_image)

  setting(:redis_operator_image, :image, @redis_operator_image)

  setting(:ceph_image, :ceph_image, @ceph_image)
end
