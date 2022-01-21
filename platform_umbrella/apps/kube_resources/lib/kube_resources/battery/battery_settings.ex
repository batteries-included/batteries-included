defmodule KubeResources.BatterySettings do
  @namespace "battery-core"

  @control_image "k3d-k3s-default-registry:5000/battery/control"
  @control_version "ddaa3d8-dirty"
  @control_name "control-server"

  @default_pg_cluster_name "default-control"
  @default_pg_username "postgres"

  @spec namespace(map) :: String.t()
  def namespace(config), do: Map.get(config, "namespace", @namespace)

  @spec control_server_image(map) :: String.t()
  def control_server_image(config), do: Map.get(config, "control.image", @control_image)

  @spec control_server_version(map) :: String.t()
  def control_server_version(config), do: Map.get(config, "control.version", @control_version)
  def control_server_name(config), do: Map.get(config, "control.name", @control_name)

  def postgres_host(config) do
    namespace = namespace(config)
    default = "#{@default_pg_cluster_name}.#{namespace}.svc.cluster.local"
    Map.get(config, "postgres.host", default)
  end

  def postgres_db(config) do
    Map.get(config, "postgres.db", System.get_env("POSTGRES_DB") || "control-dev")
  end

  def postgres_credential_secret(_config) do
    "#{@default_pg_username}.#{@default_pg_cluster_name}.credentials.postgresql.acid.zalan.do"
  end
end
