defmodule KubeResources.BatterySettings do
  import KubeExt.MapSettings

  @control_image "battery-registry:5000/battery/control:c6f4bd1-dirty1"
  @control_name "control-server"

  @default_pg_cluster_name "pg-control"
  @default_pg_username "controlserver"
  @default_pg_db "control"

  setting(:control_server_image, :image, @control_image)
  setting(:control_server_name, :name, @control_name)

  setting(
    :control_server_pg_host,
    :pg_host,
    "#{@default_pg_cluster_name}.battery-core.svc.cluster.local"
  )

  setting(:control_server_pg_db, :pg_db) do
    System.get_env("POSTGRES_DB") || @default_pg_db
  end

  setting(
    :control_server_pg_secret,
    :pg_secret,
    "#{@default_pg_username}.#{@default_pg_cluster_name}.credentials.postgresql.acid.zalan.do"
  )
end
