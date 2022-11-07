defmodule KubeRawResources.Battery do
  alias KubeExt.Builder, as: B
  alias KubeRawResources.BatterySettings

  @app_name "batteries-included"

  @default_pg_cluster %{
    :name => "control",
    :postgres_version => "14",
    :num_instances => 1,
    :storage_size => "500M",
    :type => :internal,
    :users => [
      %{username: "controlserver", roles: ["superuser", "createrole", "createdb", "login"]}
    ],
    :databases => [%{name: "control", owner: "controlserver"}],
    :team_name => "pg"
  }

  def control_cluster do
    @default_pg_cluster
  end

  def namespace(config) do
    name = BatterySettings.namespace(config)

    B.build_resource(:namespace)
    |> B.app_labels(@app_name)
    |> B.name(name)
    |> B.label("istio-injection", "enabled")
  end

  def istio_namespace(_config) do
    B.build_resource(:namespace)
    |> B.app_labels(@app_name)
    |> B.name("battery-istio")
  end

  def service_account(config) do
    namespace = BatterySettings.namespace(config)

    B.build_resource(:service_account)
    |> B.namespace(namespace)
    |> B.name("battery-admin")
    |> B.app_labels(@app_name)
  end

  def cluster_role_binding(config) do
    namespace = BatterySettings.namespace(config)

    B.build_resource(:cluster_role_binding)
    |> B.name("battery-admin-cluster-admin")
    |> B.app_labels(@app_name)
    |> Map.put(
      "roleRef",
      B.build_cluster_role_ref("cluster-admin")
    )
    |> Map.put("subjects", [
      B.build_service_account("battery-admin", namespace)
    ])
  end

  def materialize(config) do
    %{
      "/namespace" => namespace(config),
      "/istio_namespace" => istio_namespace(config),
      "/service_account" => service_account(config),
      "/cluster_role_binding" => cluster_role_binding(config)
    }
  end
end
