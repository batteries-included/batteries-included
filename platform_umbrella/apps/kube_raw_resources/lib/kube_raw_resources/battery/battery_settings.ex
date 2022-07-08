defmodule KubeRawResources.BatterySettings do
  import KubeExt.MapSettings

  @namespace "battery-core"

  @control_image "battery-registry:5000/battery/control:c6f4bd1-dirty1"
  @control_name "control-server"

  @default_pg_cluster_name "pg-control"
  @default_pg_username "controlserver"
  @default_pg_db "control"

  setting(:namespace, :namespace, @namespace)

  setting(:control_server_image, :image, @control_image)
  setting(:control_server_name, :name, @control_name)

  setting(
    :control_server_pg_host,
    :pg_host,
    "#{@default_pg_cluster_name}.#{@namespace}.svc.cluster.local"
  )

  def default_pg_db, do: fn -> System.get_env("POSTGRES_DB") || @default_pg_db end

  setting_fn(:control_server_pg_db, :pg_db, &default_pg_db/0)

  setting(
    :control_server_pg_secret,
    :pg_secret,
    "#{@default_pg_username}.#{@default_pg_cluster_name}.credentials.postgresql.acid.zalan.do"
  )
end
